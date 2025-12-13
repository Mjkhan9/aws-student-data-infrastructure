#===============================================================================
# OUTPUTS - Exported Values for Reference and Integration
#===============================================================================

#-------------------------------------------------------------------------------
# VPC Outputs
#-------------------------------------------------------------------------------

output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "vpc_arn" {
  description = "ARN of the VPC"
  value       = aws_vpc.main.arn
}

#-------------------------------------------------------------------------------
# Subnet Outputs
#-------------------------------------------------------------------------------

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "public_subnet_cidrs" {
  description = "List of public subnet CIDR blocks"
  value       = aws_subnet.public[*].cidr_block
}

output "application_subnet_ids" {
  description = "List of application subnet IDs"
  value       = aws_subnet.application[*].id
}

output "application_subnet_cidrs" {
  description = "List of application subnet CIDR blocks"
  value       = aws_subnet.application[*].cidr_block
}

output "database_subnet_ids" {
  description = "List of database subnet IDs"
  value       = aws_subnet.database[*].id
}

output "database_subnet_cidrs" {
  description = "List of database subnet CIDR blocks"
  value       = aws_subnet.database[*].cidr_block
}

output "db_subnet_group_name" {
  description = "Name of the RDS subnet group"
  value       = aws_db_subnet_group.main.name
}

#-------------------------------------------------------------------------------
# Gateway Outputs
#-------------------------------------------------------------------------------

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = var.enable_nat_gateway ? aws_nat_gateway.main[0].id : null
}

output "nat_gateway_public_ip" {
  description = "Public IP address of the NAT Gateway"
  value       = var.enable_nat_gateway ? aws_eip.nat[0].public_ip : null
}

#-------------------------------------------------------------------------------
# Security Group Outputs
#-------------------------------------------------------------------------------

output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "app_security_group_id" {
  description = "ID of the application security group"
  value       = aws_security_group.app.id
}

output "db_security_group_id" {
  description = "ID of the database security group"
  value       = aws_security_group.db.id
}

output "bastion_security_group_id" {
  description = "ID of the bastion security group"
  value       = aws_security_group.bastion.id
}

#-------------------------------------------------------------------------------
# Security Group Chain Summary
#-------------------------------------------------------------------------------

output "security_group_chain" {
  description = "Security group chain showing allowed traffic flow"
  value = {
    "1_internet_to_alb" = {
      source      = "Internet (${join(", ", var.alb_allowed_cidrs)})"
      destination = aws_security_group.alb.id
      ports       = "443, 80"
    }
    "2_alb_to_app" = {
      source      = aws_security_group.alb.id
      destination = aws_security_group.app.id
      ports       = "443"
    }
    "3_app_to_db" = {
      source      = aws_security_group.app.id
      destination = aws_security_group.db.id
      ports       = "5432"
    }
  }
}

#-------------------------------------------------------------------------------
# Route Table Outputs
#-------------------------------------------------------------------------------

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

output "application_route_table_id" {
  description = "ID of the application route table"
  value       = aws_route_table.application.id
}

output "database_route_table_id" {
  description = "ID of the database route table (isolated)"
  value       = aws_route_table.database.id
}

#-------------------------------------------------------------------------------
# Monitoring Outputs
#-------------------------------------------------------------------------------

output "vpc_flow_log_group_name" {
  description = "Name of the CloudWatch Log Group for VPC Flow Logs"
  value       = var.enable_vpc_flow_logs ? aws_cloudwatch_log_group.vpc_flow_logs[0].name : null
}

output "vpc_flow_log_id" {
  description = "ID of the VPC Flow Log"
  value       = var.enable_vpc_flow_logs ? aws_flow_log.main[0].id : null
}

#-------------------------------------------------------------------------------
# Summary Output
#-------------------------------------------------------------------------------

output "infrastructure_summary" {
  description = "Summary of the deployed infrastructure"
  value = {
    project_name         = var.project_name
    environment          = var.environment
    region               = var.aws_region
    vpc_cidr             = var.vpc_cidr
    availability_zones   = data.aws_availability_zones.available.names
    public_subnets       = length(aws_subnet.public)
    application_subnets  = length(aws_subnet.application)
    database_subnets     = length(aws_subnet.database)
    nat_gateway_enabled  = var.enable_nat_gateway
    flow_logs_enabled    = var.enable_vpc_flow_logs
    cloudtrail_enabled   = var.enable_cloudtrail
    vpc_endpoints_enabled = var.enable_vpc_endpoints
  }
}

#-------------------------------------------------------------------------------
# KMS Key Outputs
#-------------------------------------------------------------------------------

output "kms_rds_key_arn" {
  description = "ARN of the KMS key for RDS encryption"
  value       = aws_kms_key.rds.arn
}

output "kms_rds_key_id" {
  description = "ID of the KMS key for RDS encryption"
  value       = aws_kms_key.rds.key_id
}

output "kms_s3_key_arn" {
  description = "ARN of the KMS key for S3 encryption"
  value       = aws_kms_key.s3.arn
}

output "kms_ebs_key_arn" {
  description = "ARN of the KMS key for EBS encryption"
  value       = aws_kms_key.ebs.arn
}

output "kms_secrets_key_arn" {
  description = "ARN of the KMS key for Secrets Manager"
  value       = aws_kms_key.secrets.arn
}

#-------------------------------------------------------------------------------
# CloudTrail Outputs
#-------------------------------------------------------------------------------

output "cloudtrail_arn" {
  description = "ARN of the CloudTrail trail"
  value       = var.enable_cloudtrail ? aws_cloudtrail.main[0].arn : null
}

output "cloudtrail_s3_bucket" {
  description = "S3 bucket for CloudTrail logs"
  value       = var.enable_cloudtrail ? aws_s3_bucket.cloudtrail[0].id : null
}

output "cloudtrail_log_group" {
  description = "CloudWatch Log Group for CloudTrail"
  value       = var.enable_cloudtrail ? aws_cloudwatch_log_group.cloudtrail[0].name : null
}

#-------------------------------------------------------------------------------
# VPC Endpoint Outputs
#-------------------------------------------------------------------------------

output "vpc_endpoint_s3_id" {
  description = "ID of the S3 VPC endpoint"
  value       = var.enable_vpc_endpoints ? aws_vpc_endpoint.s3[0].id : null
}

output "vpc_endpoint_dynamodb_id" {
  description = "ID of the DynamoDB VPC endpoint"
  value       = var.enable_vpc_endpoints ? aws_vpc_endpoint.dynamodb[0].id : null
}

output "vpc_endpoints_security_group_id" {
  description = "Security group ID for VPC interface endpoints"
  value       = var.enable_vpc_endpoints ? aws_security_group.vpc_endpoints[0].id : null
}

#-------------------------------------------------------------------------------
# IAM Outputs
#-------------------------------------------------------------------------------

output "iam_group_name" {
  description = "Name of the IAM group for student data access"
  value       = aws_iam_group.student_data_access.name
}

output "iam_group_arn" {
  description = "ARN of the IAM group for student data access"
  value       = aws_iam_group.student_data_access.arn
}

output "mfa_enforcement_policy_arn" {
  description = "ARN of the MFA enforcement policy"
  value       = aws_iam_policy.mfa_enforcement.arn
}

