# Infrastructure as Code - Three-Tier VPC

Production-ready Terraform configuration for deploying a secure, FERPA-aligned AWS infrastructure.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        VPC: 172.32.0.0/16 (us-east-1)                       │
├─────────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  PUBLIC SUBNETS (172.32.1.0/24, 172.32.2.0/24)                      │   │
│  │  • Internet Gateway    • NAT Gateway    • Bastion Host              │   │
│  │  Route: 0.0.0.0/0 → IGW                                             │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                        │
│                              ┌─────┴─────┐                                  │
│                              │  ALB-SG   │ ← 443 from Internet              │
│                              └─────┬─────┘                                  │
│                                    ▼                                        │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  APPLICATION SUBNETS (172.32.10.0/24, 172.32.11.0/24)               │   │
│  │  • ECS Fargate    • Lambda    • Application Load Balancer           │   │
│  │  Route: 0.0.0.0/0 → NAT Gateway                                     │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                        │
│                              ┌─────┴─────┐                                  │
│                              │  APP-SG   │ ← 443 from ALB-SG only           │
│                              └─────┬─────┘                                  │
│                                    ▼                                        │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  DATABASE SUBNETS (172.32.20.0/24, 172.32.21.0/24)                  │   │
│  │  • RDS PostgreSQL (Multi-AZ)    • KMS Encrypted                     │   │
│  │  Route: NO INTERNET ACCESS (Isolated)                               │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                              ┌───────────┐                                  │
│                              │   DB-SG   │ ← 5432 from APP-SG only          │
│                              └───────────┘                                  │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Security Group Chain

Traffic flow is strictly controlled through chained security groups:

| Security Group | Inbound Rule | Source |
|----------------|--------------|--------|
| `alb-sg` | TCP 443 | `0.0.0.0/0` (Internet) |
| `app-sg` | TCP 443 | `alb-sg` only |
| `db-sg` | TCP 5432 | `app-sg` only |
| `bastion-sg` | TCP 22 | Corporate IPs only |

## Quick Start

### Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0.0
- AWS CLI configured with appropriate credentials
- IAM permissions for VPC, EC2, and CloudWatch

### Deploy

```bash
# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Apply infrastructure
terraform apply

# Destroy when done
terraform destroy
```

### Configuration

Create a `terraform.tfvars` file to customize:

```hcl
# terraform.tfvars
project_name          = "student-data"
environment           = "dev"
aws_region            = "us-east-1"

# Network Configuration
vpc_cidr              = "172.32.0.0/16"
public_subnet_cidrs   = ["172.32.1.0/24", "172.32.2.0/24"]
app_subnet_cidrs      = ["172.32.10.0/24", "172.32.11.0/24"]
db_subnet_cidrs       = ["172.32.20.0/24", "172.32.21.0/24"]

# Security Configuration
bastion_allowed_cidrs = ["YOUR_CORPORATE_IP/32"]
alb_allowed_cidrs     = ["0.0.0.0/0"]

# Features
enable_nat_gateway    = true
enable_vpc_flow_logs  = true
```

## Files

| File | Purpose |
|------|---------|
| `main.tf` | VPC, subnets, gateways, route tables, flow logs |
| `security-groups.tf` | Security groups with chained rules, NACLs |
| `iam.tf` | IAM group, MFA enforcement, least-privilege policies |
| `kms.tf` | Customer-managed KMS keys for RDS, S3, EBS, Secrets |
| `cloudtrail.tf` | CloudTrail audit logging with S3 storage and alarms |
| `vpc-endpoints.tf` | VPC endpoints for private AWS service access |
| `variables.tf` | Configurable parameters with validation |
| `outputs.tf` | Exported values for integration |

## Key Design Decisions

### Why Three Tiers?
- **Defense in depth**: Each tier has distinct security boundaries
- **Blast radius reduction**: Compromise of one tier doesn't expose others
- **Compliance**: FERPA requires data isolation

### Why Security Group Chaining?
- **Least privilege**: Each resource only accepts traffic from its upstream
- **No skip-level access**: Database cannot be reached from internet, ever
- **Audit-friendly**: Clear traffic flow for compliance reviews

### Why NAT Gateway?
- **Secure updates**: Application tier can pull patches without public IPs
- **API access**: Outbound calls to AWS services and external APIs
- **No inbound exposure**: Private subnets remain unreachable from internet

## Estimated Costs

| Resource | Monthly Cost (us-east-1) |
|----------|-------------------------|
| NAT Gateway | ~$32 + data transfer |
| VPC Flow Logs | ~$0.50/GB ingested |
| EIP | Free (when attached) |
| CloudTrail | Free (management events) |
| CloudTrail S3 | ~$0.023/GB stored |
| KMS Keys | ~$1/key/month + usage |
| VPC Endpoints (Gateway) | Free (S3, DynamoDB) |
| VPC Endpoints (Interface) | ~$7.20/endpoint/month |

*Actual costs depend on traffic volume. See [AWS Pricing Calculator](https://calculator.aws/).*

## Security Features

**MFA Enforcement** - Users must authenticate with MFA for console access

**KMS Encryption** - Customer-managed keys for RDS, S3, EBS, and Secrets Manager

**CloudTrail** - API audit logging with CloudWatch integration and security alarms

**VPC Endpoints** - Private access to S3, DynamoDB, and Secrets Manager without internet traversal

**Password Policy** - 14+ characters, complexity requirements, 90-day rotation

**Security Alarms** - CloudWatch alarms for unauthorized access attempts and root account usage

## Next Steps

After deploying this infrastructure:

1. **Add RDS** - Use `db_subnet_group_name` and `kms_rds_key_arn` outputs for encrypted database
2. **Add ALB** - Deploy in public subnets with `alb_security_group_id`
3. **Add ECS** - Deploy Fargate tasks in application subnets
4. **Enable GuardDuty** - Add threat detection for the VPC
5. **Store Secrets** - Use Secrets Manager with `kms_secrets_key_arn` for DB credentials

## Author

**Mohammad Khan**  
University of Houston  
AWS Certified Solutions Architect
