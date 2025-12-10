#===============================================================================
# AWS Student Data Infrastructure - Main Terraform Configuration
#===============================================================================
# Author: Mohammad Khan
# Purpose: Production-ready 3-tier VPC architecture for secure student data systems
# 
# This configuration implements:
# - Three-tier network isolation (Public/Application/Database)
# - Defense-in-depth security with chained security groups
# - Multi-AZ high availability
# - FERPA-aligned security controls
#===============================================================================

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Uncomment to use S3 backend for state management
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "student-data-infrastructure/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-lock"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "StudentDataInfrastructure"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = "Mohammad Khan"
      Compliance  = "FERPA"
    }
  }
}

#===============================================================================
# DATA SOURCES
#===============================================================================

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

#===============================================================================
# VPC - Core Network Infrastructure
#===============================================================================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

#===============================================================================
# INTERNET GATEWAY - Public Internet Access Point
#===============================================================================

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

#===============================================================================
# SUBNETS - Three-Tier Network Segmentation
#===============================================================================

# Public Subnets (Tier 1) - NAT Gateway, Bastion, ALB
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-${data.aws_availability_zones.available.names[count.index]}"
    Tier = "Public"
  }
}

# Application Subnets (Tier 2) - ECS Fargate, Lambda
resource "aws_subnet" "application" {
  count             = length(var.app_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.app_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.project_name}-app-${data.aws_availability_zones.available.names[count.index]}"
    Tier = "Application"
  }
}

# Database Subnets (Tier 3) - RDS, isolated from internet
resource "aws_subnet" "database" {
  count             = length(var.db_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.db_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.project_name}-db-${data.aws_availability_zones.available.names[count.index]}"
    Tier = "Database"
  }
}

#===============================================================================
# ELASTIC IP - For NAT Gateway High Availability
#===============================================================================

resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? 1 : 0
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-nat-eip"
  }

  depends_on = [aws_internet_gateway.main]
}

#===============================================================================
# NAT GATEWAY - Secure Outbound Internet for Private Subnets
#===============================================================================

resource "aws_nat_gateway" "main" {
  count         = var.enable_nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "${var.project_name}-nat-gw"
  }

  depends_on = [aws_internet_gateway.main]
}

#===============================================================================
# ROUTE TABLES - Traffic Flow Control
#===============================================================================

# Public Route Table - Direct internet access via IGW
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# Application Route Table - Internet via NAT Gateway
resource "aws_route_table" "application" {
  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[0].id
    }
  }

  tags = {
    Name = "${var.project_name}-app-rt"
  }
}

# Database Route Table - NO internet access (isolated)
resource "aws_route_table" "database" {
  vpc_id = aws_vpc.main.id

  # No routes to internet - completely isolated

  tags = {
    Name = "${var.project_name}-db-rt"
  }
}

#===============================================================================
# ROUTE TABLE ASSOCIATIONS
#===============================================================================

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "application" {
  count          = length(aws_subnet.application)
  subnet_id      = aws_subnet.application[count.index].id
  route_table_id = aws_route_table.application.id
}

resource "aws_route_table_association" "database" {
  count          = length(aws_subnet.database)
  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}

#===============================================================================
# DB SUBNET GROUP - For RDS Multi-AZ Deployment
#===============================================================================

resource "aws_db_subnet_group" "main" {
  name        = "${var.project_name}-db-subnet-group"
  description = "Database subnet group for student data RDS instances"
  subnet_ids  = aws_subnet.database[*].id

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

#===============================================================================
# VPC FLOW LOGS - Network Traffic Monitoring
#===============================================================================

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  count             = var.enable_vpc_flow_logs ? 1 : 0
  name              = "/aws/vpc/${var.project_name}-flow-logs"
  retention_in_days = var.flow_logs_retention_days

  tags = {
    Name = "${var.project_name}-vpc-flow-logs"
  }
}

resource "aws_iam_role" "vpc_flow_logs" {
  count = var.enable_vpc_flow_logs ? 1 : 0
  name  = "${var.project_name}-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-vpc-flow-logs-role"
  }
}

resource "aws_iam_role_policy" "vpc_flow_logs" {
  count = var.enable_vpc_flow_logs ? 1 : 0
  name  = "${var.project_name}-vpc-flow-logs-policy"
  role  = aws_iam_role.vpc_flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_flow_log" "main" {
  count                = var.enable_vpc_flow_logs ? 1 : 0
  iam_role_arn         = aws_iam_role.vpc_flow_logs[0].arn
  log_destination      = aws_cloudwatch_log_group.vpc_flow_logs[0].arn
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.main.id
  max_aggregation_interval = 60

  tags = {
    Name = "${var.project_name}-vpc-flow-log"
  }
}

