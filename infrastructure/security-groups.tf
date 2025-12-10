#===============================================================================
# SECURITY GROUPS - Defense-in-Depth with Chained Rules
#===============================================================================
# Security Group Chain: ALB -> App -> Database
# Each tier can only communicate with adjacent tiers (no skip-level access)
#===============================================================================

#-------------------------------------------------------------------------------
# ALB Security Group - Internet-Facing Load Balancer
#-------------------------------------------------------------------------------
# Accepts HTTPS traffic from the internet (or specific CIDRs)
# This is the ONLY entry point for external traffic

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Security group for Application Load Balancer - accepts HTTPS from internet"
  vpc_id      = aws_vpc.main.id

  # Inbound: HTTPS from allowed CIDRs (default: internet)
  ingress {
    description = "HTTPS from allowed sources"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.alb_allowed_cidrs
  }

  # Inbound: HTTP for redirect to HTTPS (optional)
  ingress {
    description = "HTTP for HTTPS redirect"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.alb_allowed_cidrs
  }

  # Outbound: Only to application tier
  egress {
    description     = "To application tier only"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  tags = {
    Name = "${var.project_name}-alb-sg"
    Tier = "Public"
  }

  lifecycle {
    create_before_destroy = true
  }
}

#-------------------------------------------------------------------------------
# Application Security Group - ECS Fargate / Lambda
#-------------------------------------------------------------------------------
# Accepts traffic ONLY from ALB security group
# Can communicate with database tier and make outbound calls via NAT

resource "aws_security_group" "app" {
  name        = "${var.project_name}-app-sg"
  description = "Security group for application tier - accepts traffic from ALB only"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-app-sg"
    Tier = "Application"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Inbound rule: HTTPS from ALB only (SG-to-SG reference)
resource "aws_security_group_rule" "app_ingress_alb" {
  type                     = "ingress"
  description              = "HTTPS from ALB only"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.app.id
}

# Outbound rule: PostgreSQL to database tier
resource "aws_security_group_rule" "app_egress_db" {
  type                     = "egress"
  description              = "PostgreSQL to database tier"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.db.id
  security_group_id        = aws_security_group.app.id
}

# Outbound rule: HTTPS for external API calls (via NAT Gateway)
resource "aws_security_group_rule" "app_egress_https" {
  type              = "egress"
  description       = "HTTPS for external API calls via NAT"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.app.id
}

#-------------------------------------------------------------------------------
# Database Security Group - RDS PostgreSQL
#-------------------------------------------------------------------------------
# Accepts traffic ONLY from application security group
# NO outbound internet access - completely isolated

resource "aws_security_group" "db" {
  name        = "${var.project_name}-db-sg"
  description = "Security group for database tier - accepts traffic from app tier only"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-db-sg"
    Tier = "Database"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Inbound rule: PostgreSQL from application tier only
resource "aws_security_group_rule" "db_ingress_app" {
  type                     = "ingress"
  description              = "PostgreSQL from application tier only"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app.id
  security_group_id        = aws_security_group.db.id
}

# No egress rules - database cannot initiate outbound connections

#-------------------------------------------------------------------------------
# Bastion Security Group - Administrative Access
#-------------------------------------------------------------------------------
# Restricted SSH access for administrative purposes only
# Only accessible from specified corporate IP ranges

resource "aws_security_group" "bastion" {
  name        = "${var.project_name}-bastion-sg"
  description = "Security group for bastion host - SSH from corporate IPs only"
  vpc_id      = aws_vpc.main.id

  # Inbound: SSH from corporate IPs only
  ingress {
    description = "SSH from corporate IPs"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.bastion_allowed_cidrs
  }

  # Outbound: SSH to application tier for management
  egress {
    description = "SSH to internal resources"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Outbound: HTTPS for package updates
  egress {
    description = "HTTPS for updates"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-bastion-sg"
    Tier = "Public"
  }

  lifecycle {
    create_before_destroy = true
  }
}

#===============================================================================
# NETWORK ACLs - Subnet-Level Stateless Filtering
#===============================================================================

#-------------------------------------------------------------------------------
# Public Subnet NACL
#-------------------------------------------------------------------------------

resource "aws_network_acl" "public" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.public[*].id

  # Inbound: Allow HTTPS from internet
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  # Inbound: Allow HTTP for redirect
  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  # Inbound: Allow SSH from corporate (if specified)
  dynamic "ingress" {
    for_each = var.bastion_allowed_cidrs
    content {
      protocol   = "tcp"
      rule_no    = 120 + index(var.bastion_allowed_cidrs, ingress.value)
      action     = "allow"
      cidr_block = ingress.value
      from_port  = 22
      to_port    = 22
    }
  }

  # Inbound: Allow ephemeral ports (return traffic)
  ingress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # Outbound: Allow all (SGs provide fine-grained control)
  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "${var.project_name}-public-nacl"
  }
}

#-------------------------------------------------------------------------------
# Application Subnet NACL
#-------------------------------------------------------------------------------

resource "aws_network_acl" "application" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.application[*].id

  # Inbound: Allow from VPC (ALB traffic)
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = 443
    to_port    = 443
  }

  # Inbound: Allow ephemeral ports (return traffic from NAT)
  ingress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # Outbound: Allow to VPC (database access)
  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = 5432
    to_port    = 5432
  }

  # Outbound: Allow HTTPS (external APIs via NAT)
  egress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  # Outbound: Allow ephemeral ports
  egress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  tags = {
    Name = "${var.project_name}-app-nacl"
  }
}

#-------------------------------------------------------------------------------
# Database Subnet NACL - Most Restrictive
#-------------------------------------------------------------------------------

resource "aws_network_acl" "database" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.database[*].id

  # Inbound: PostgreSQL from VPC only (application tier)
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = 5432
    to_port    = 5432
  }

  # Outbound: Ephemeral ports to VPC only (response traffic)
  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = 1024
    to_port    = 65535
  }

  # EXPLICITLY DENY all internet traffic
  egress {
    protocol   = "-1"
    rule_no    = 999
    action     = "deny"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "${var.project_name}-db-nacl"
  }
}

