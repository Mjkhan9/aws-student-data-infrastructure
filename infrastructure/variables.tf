#===============================================================================
# VARIABLES - Configurable Parameters for Student Data Infrastructure
#===============================================================================

#-------------------------------------------------------------------------------
# General Configuration
#-------------------------------------------------------------------------------

variable "project_name" {
  description = "Name prefix for all resources"
  type        = string
  default     = "student-data"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

#-------------------------------------------------------------------------------
# VPC Configuration
#-------------------------------------------------------------------------------

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "172.32.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "VPC CIDR must be a valid CIDR block."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (one per AZ)"
  type        = list(string)
  default     = ["172.32.1.0/24", "172.32.2.0/24"]

  validation {
    condition     = length(var.public_subnet_cidrs) >= 2
    error_message = "At least 2 public subnets required for high availability."
  }
}

variable "app_subnet_cidrs" {
  description = "CIDR blocks for application subnets (one per AZ)"
  type        = list(string)
  default     = ["172.32.10.0/24", "172.32.11.0/24"]

  validation {
    condition     = length(var.app_subnet_cidrs) >= 2
    error_message = "At least 2 application subnets required for high availability."
  }
}

variable "db_subnet_cidrs" {
  description = "CIDR blocks for database subnets (one per AZ)"
  type        = list(string)
  default     = ["172.32.20.0/24", "172.32.21.0/24"]

  validation {
    condition     = length(var.db_subnet_cidrs) >= 2
    error_message = "At least 2 database subnets required for RDS Multi-AZ."
  }
}

#-------------------------------------------------------------------------------
# NAT Gateway Configuration
#-------------------------------------------------------------------------------

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnet internet access"
  type        = bool
  default     = true
}

#-------------------------------------------------------------------------------
# Security Group Configuration
#-------------------------------------------------------------------------------

variable "alb_allowed_cidrs" {
  description = "CIDR blocks allowed to access the ALB (default: internet)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "bastion_allowed_cidrs" {
  description = "CIDR blocks allowed to SSH to bastion host (corporate IPs)"
  type        = list(string)
  default     = ["10.0.0.0/8"]  # Replace with actual corporate IP ranges

  validation {
    condition     = length(var.bastion_allowed_cidrs) > 0
    error_message = "At least one CIDR block must be specified for bastion access."
  }
}

#-------------------------------------------------------------------------------
# Monitoring Configuration
#-------------------------------------------------------------------------------

variable "enable_vpc_flow_logs" {
  description = "Enable VPC Flow Logs for network monitoring"
  type        = bool
  default     = true
}

variable "flow_logs_retention_days" {
  description = "Number of days to retain VPC Flow Logs"
  type        = number
  default     = 30

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.flow_logs_retention_days)
    error_message = "Flow logs retention must be a valid CloudWatch Logs retention period."
  }
}

#-------------------------------------------------------------------------------
# Tagging Configuration
#-------------------------------------------------------------------------------

variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

