# AWS Student Data Infrastructure

**Production-grade cloud architecture for secure academic data systems**

[![Terraform](https://img.shields.io/badge/Terraform-1.0+-623CE4?logo=terraform)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-VPC%20|%20IAM%20|%20RDS-FF9900?logo=amazon-aws)](https://aws.amazon.com/)
[![Python](https://img.shields.io/badge/Python-3.8+-3776AB?logo=python)](https://www.python.org/)
[![License](https://img.shields.io/badge/License-Educational-blue)](#)

---

## Overview

This repository contains **Infrastructure as Code (IaC)** and **automation scripts** for deploying a secure, FERPA-aligned AWS environment for student data systems.

### What's Inside

| Directory | Contents | Purpose |
|-----------|----------|---------|
| [`/infrastructure`](./infrastructure) | Terraform configurations | Deploy 3-tier VPC with security controls |
| [`/scripts`](./scripts) | Python/Boto3 automation | IAM provisioning, security auditing |
| [`/docs`](./docs) | Interactive documentation | Architecture visualizations, demos |

---

## Architecture

```
┌──────────────────────────────────────────────────────────────────────────┐
│                     VPC: 172.32.0.0/16 (Multi-AZ)                        │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌────────────────┐   ┌────────────────┐   ┌────────────────┐           │
│  │  PUBLIC TIER   │   │   APP TIER     │   │   DB TIER      │           │
│  │  ────────────  │   │  ────────────  │   │  ────────────  │           │
│  │  • NAT Gateway │──▶│  • ECS Fargate │──▶│  • RDS (Multi- │           │
│  │  • Bastion     │   │  • Lambda      │   │    AZ)         │           │
│  │  • ALB         │   │  • APIs        │   │  • KMS Encrypt │           │
│  │                │   │                │   │  • NO INTERNET │           │
│  │  IGW Attached  │   │  NAT Outbound  │   │  ISOLATED      │           │
│  └────────────────┘   └────────────────┘   └────────────────┘           │
│         │                    │                    │                      │
│         ▼                    ▼                    ▼                      │
│  ┌─────────────────────────────────────────────────────────────┐        │
│  │          Security & Audit Layer                              │        │
│  │  CloudTrail • VPC Flow Logs • GuardDuty • CloudWatch • KMS  │        │
│  └─────────────────────────────────────────────────────────────┘        │
└──────────────────────────────────────────────────────────────────────────┘
```

### Security Group Chain

```
Internet ──[443]──▶ ALB-SG ──[443]──▶ APP-SG ──[5432]──▶ DB-SG
                      │
   Corporate IPs ──[22]──▶ Bastion-SG
```

No skip-level access. Database tier is **completely isolated** from the internet.

---

## Quick Start

### 1. Deploy Infrastructure (Terraform)

```bash
cd infrastructure

# Initialize and deploy
terraform init
terraform plan
terraform apply
```

See [`/infrastructure/README.md`](./infrastructure/README.md) for configuration options.

### 2. Run IAM Automation (Python)

```bash
cd scripts

# Install dependencies
pip install boto3

# Run provisioning (demo mode by default)
python iam_provisioner.py
```

Output:
```
=== IAM Provisioning System (Enhanced Version) ===
[INFO] Validating IAM group 'StudentDataRestrictedAccess'...
[INFO] Provisioning user: registrar_office_analyst
[INFO] [DEMO] Provisioned user 'registrar_office_analyst' with least-privilege access.
...
============================================================
Provisioning Summary
============================================================
Total users: 5
Successful: 5
Execution time: 0.25 seconds
Efficiency gain: 40% faster than manual IAM onboarding.
```

### 3. View Documentation

Open [`/docs/index.html`](./docs/index.html) in a browser, or visit the live site:

**[📊 Live Demo & Documentation](https://mjkhan9.github.io/aws-student-data-infrastructure/)**

---

## Key Features

### Infrastructure (Terraform)

- ✅ **Three-tier VPC** with network isolation
- ✅ **Security group chaining** (ALB → App → DB)
- ✅ **Multi-AZ deployment** for high availability
- ✅ **VPC Flow Logs** for network monitoring
- ✅ **NACLs** for subnet-level stateless filtering
- ✅ **Database isolation** (no internet routes)

### Automation (Python/Boto3)

- ✅ **IAM user provisioning** with least-privilege groups
- ✅ **Input validation** and error handling
- ✅ **Retry logic** with exponential backoff
- ✅ **Comprehensive logging** for audit trails
- ✅ **Demo mode** for safe testing

### Documentation (Web)

- ✅ **Interactive VPC diagram** with clickable components
- ✅ **Security attack simulator** demonstrating defenses
- ✅ **Cost calculator** with real AWS pricing
- ✅ **Live IAM demo** showing script execution

---

## Project Structure

```
aws-student-data-infrastructure/
│
├── infrastructure/              # 🏗️ Terraform IaC
│   ├── main.tf                  # VPC, subnets, gateways, flow logs
│   ├── security-groups.tf       # Security groups, NACLs
│   ├── variables.tf             # Configurable parameters
│   ├── outputs.tf               # Exported values
│   └── README.md                # Deployment guide
│
├── scripts/                     # 🐍 Python Automation
│   └── iam_provisioner.py       # IAM user/group provisioning
│
├── docs/                        # 📄 Web Documentation (GitHub Pages)
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

## Technology Stack

| Category | Technologies |
|----------|--------------|
| **IaC** | Terraform 1.0+, HCL |
| **Cloud** | AWS (VPC, IAM, RDS, KMS, CloudTrail, GuardDuty) |
| **Automation** | Python 3.8+, Boto3 |
| **Documentation** | HTML5, CSS3, JavaScript |

---

## Compliance Alignment

This architecture implements controls aligned with:

- **FERPA** (Family Educational Rights and Privacy Act)
- **AWS Well-Architected Framework** (Security Pillar)
- **CIS AWS Foundations Benchmark**

| Control | Implementation |
|---------|----------------|
| Data Encryption | KMS (at rest), TLS 1.2+ (in transit) |
| Network Isolation | Private subnets, no public DB access |
| Access Logging | CloudTrail, VPC Flow Logs |
| Least Privilege | IAM groups with minimal permissions |
| Threat Detection | GuardDuty integration |

---

## Author

**Mohammad Khan**  
IT Operations Specialist | AWS Certified Solutions Architect  
University of Houston

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-0077B5?logo=linkedin)](https://linkedin.com/in/mohammad-jkhan/)

---

## License

This project is created for educational and portfolio demonstration purposes.

---

*Last updated: December 2025*
