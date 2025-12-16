# AWS Student Data Infrastructure

Secure cloud architecture for academic data systems, built with Terraform and Python automation.

I created this project to demonstrate FERPA-aligned infrastructure patterns. The design isolates student data in private subnets with no direct internet access, implements encryption at rest and in transit, and includes comprehensive audit logging.

[![AWS](https://img.shields.io/badge/AWS-VPC%20|%20IAM%20|%20RDS-FF9900?logo=amazon-aws)](https://aws.amazon.com/)

**[Live Documentation](https://mjkhan9.github.io/aws-student-data-infrastructure/)**

---

## What's Inside

- `/infrastructure` - Terraform configurations for deploying a 3-tier VPC with security controls
- `/scripts` - Python/Boto3 automation for IAM provisioning and security auditing
- `/docs` - Interactive documentation with architecture visualizations

---

## Architecture

```
VPC (172.32.0.0/16) - Multi-AZ
├── Public Tier: NAT Gateway, Bastion, ALB
├── App Tier: ECS Fargate, Lambda
└── DB Tier: RDS (isolated, no internet)

Security Layer: CloudTrail, VPC Flow Logs, GuardDuty, KMS
```

### Security Group Chain

```
Internet ──[443]──▶ ALB-SG ──[443]──▶ APP-SG ──[5432]──▶ DB-SG
                      │
   Corporate IPs ──[22]──▶ Bastion-SG
```

No skip-level access. The database tier is completely isolated from the internet.

---

## Quick Start

### Deploy Infrastructure (Terraform)

```bash
cd infrastructure
terraform init
terraform plan
terraform apply
```

See `/infrastructure/README.md` for configuration options.

### Run IAM Automation (Python)

```bash
cd scripts
pip install boto3

# Run in DEMO mode (default - no AWS changes)
python iam_provisioner.py

# Run in LIVE mode (requires AWS credentials)
IAM_LIVE_MODE=true python iam_provisioner.py
```

Demo Output:
```
============================================================
IAM Provisioning System - DEMO MODE
============================================================
[INFO] Running in DEMO mode - no AWS changes will be made.
[INFO] Set IAM_LIVE_MODE=true to execute actual AWS API calls.

[INFO] Validating IAM group 'StudentDataRestrictedAccess'...
[INFO] [DEMO] Group 'StudentDataRestrictedAccess' verified.
[INFO] Provisioning user: registrar_office_analyst
[INFO] [DEMO] Provisioned user 'registrar_office_analyst' with least-privilege access.
...
============================================================
Provisioning Summary (DEMO MODE)
============================================================
Total users: 5
Successful: 5
Execution time: 0.25 seconds
Group policy: StudentDataRestrictedAccess with least-privilege access
[NOTE] Run with IAM_LIVE_MODE=true to create actual IAM resources
============================================================
```

---

## Key Features

### Infrastructure (Terraform)

- Three-tier VPC with network isolation
- Security group chaining (ALB → App → DB)
- Multi-AZ deployment for availability
- VPC Flow Logs for network monitoring
- NACLs for subnet-level stateless filtering
- Database isolation (no internet routes)
- CloudTrail audit logging with security alarms
- KMS encryption keys for RDS, S3, EBS, Secrets
- VPC Endpoints for private AWS service access
- MFA enforcement IAM policy
- Password policy with complexity requirements

### Automation (Python/Boto3)

- IAM user provisioning with least-privilege groups
- Input validation and error handling
- Retry logic with exponential backoff
- Comprehensive logging for audit trails
- Demo mode for safe testing
- Unit tests with pytest coverage

### CI/CD (GitHub Actions)

- Terraform validation on pull requests
- Security scanning with tfsec and Checkov
- Python linting with flake8
- Automated testing across Python 3.9-3.12
- Code coverage reporting

### Documentation (Web)

- Interactive VPC diagram with clickable components
- Security attack simulator demonstrating defenses
- Cost calculator with real AWS pricing
- Live IAM demo showing script execution

---

## Project Structure

```
aws-student-data-infrastructure/
│
├── .github/workflows/           # CI/CD Pipelines
│   ├── terraform.yml            # Terraform validation & planning
│   └── python-tests.yml         # Python testing & linting
│
├── infrastructure/              # Terraform IaC
│   ├── main.tf                  # VPC, subnets, gateways, flow logs
│   ├── security-groups.tf       # Security groups, NACLs
│   ├── iam.tf                   # MFA enforcement, least-privilege policies
│   ├── kms.tf                   # Customer-managed encryption keys
│   ├── cloudtrail.tf            # API audit logging, security alarms
│   ├── vpc-endpoints.tf         # Private AWS service access
│   ├── variables.tf             # Configurable parameters
│   ├── outputs.tf               # Exported values
│   └── README.md                # Deployment guide
│
├── scripts/                     # Python Automation
│   ├── iam_provisioner.py       # IAM user/group provisioning
│   ├── test_iam_provisioner.py  # Unit tests
│   └── requirements.txt         # Python dependencies
│
├── docs/                        # Web Documentation (GitHub Pages)
│   ├── index.html               # Landing page
│   ├── architecture.html        # Network architecture deep-dive
│   ├── automation.html          # IAM automation explanation
│   ├── security-simulator.html  # Interactive attack simulator
│   ├── cost-calculator.html     # AWS pricing calculator
│   ├── live-demo.html           # IAM script demo
│   └── ...
│
└── README.md                    # You are here
```

---

## Security & Compliance

The architecture follows FERPA requirements and AWS security best practices:

**Data Encryption**  
KMS for data at rest, TLS 1.2+ for data in transit

**Network Isolation**  
Private subnets with no public database access

**Access Logging**  
CloudTrail and VPC Flow Logs for complete visibility

**Least Privilege**  
IAM groups with minimal required permissions

**Threat Detection**  
GuardDuty integration for anomaly detection

---

## Author

**Mohammad Khan**  
IT Operations Specialist | AWS Certified Solutions Architect  
University of Houston

[LinkedIn](https://linkedin.com/in/mohammad-jkhan) · [GitHub](https://github.com/Mjkhan9)

---

## License

Created for educational and portfolio demonstration purposes.

*Last updated: December 2025*
