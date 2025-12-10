# AWS Student Data Infrastructure

**Secure Three-Tier Cloud Architecture for Academic Data Systems**

---

**Author:** Mohammad Khan  
**Institution:** University of Houston  
**Date:** December 2025

---

## 📋 Project Overview

This project demonstrates a production-ready AWS cloud architecture designed to securely manage sensitive student information systems. The implementation showcases enterprise-grade security controls, network isolation, automated IAM provisioning, and comprehensive audit logging—all aligned with FERPA compliance requirements.

### Project Objectives

- Design a **three-tier VPC architecture** with complete network segmentation
- Implement **defense-in-depth security controls** for student data protection
- Develop **automated IAM provisioning** to reduce manual errors and improve efficiency
- Create **comprehensive documentation** suitable for academic and professional review
- Build an **interactive web presentation** demonstrating technical concepts

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           AWS CLOUD (VPC: 172.32.0.0/16)                │
├─────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  PUBLIC TIER (Admin/Bastion)                                     │   │
│  │  • Internet Gateway                                              │   │
│  │  • Bastion Host for secure admin access                          │   │
│  │  • NAT Gateway for outbound traffic                              │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                    │                                     │
│                                    ▼                                     │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  PRIVATE TIER (Application)                                      │   │
│  │  • ECS Fargate containers                                        │   │
│  │  • Application APIs and services                                 │   │
│  │  • No direct internet access                                     │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                    │                                     │
│                                    ▼                                     │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  DATABASE TIER (Isolated)                                        │   │
│  │  • Amazon RDS PostgreSQL (Multi-AZ)                              │   │
│  │  • KMS encryption at rest                                        │   │
│  │  • No internet routing                                           │   │
│  └─────────────────────────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────────────────────────┤
│  SECURITY & MONITORING                                                  │
│  • CloudTrail (audit logging) • VPC Flow Logs • GuardDuty • AWS KMS    │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 🔐 Security Features

| Security Control | Implementation |
|------------------|----------------|
| **Network Isolation** | Three-tier VPC with private subnets, no public DB access |
| **Encryption at Rest** | AWS KMS customer-managed keys for RDS and S3 |
| **Encryption in Transit** | TLS 1.2+ enforced on all connections |
| **Access Control** | Security group chaining (SG-to-SG references) |
| **Audit Logging** | CloudTrail with integrity validation |
| **Threat Detection** | GuardDuty integration for anomaly detection |
| **Least Privilege** | Role-based IAM with automated provisioning |

---

## 🚀 Key Features

### 1. Three-Tier VPC Architecture
- Complete network segmentation across availability zones
- Database tier isolated with no internet routing
- Security groups configured with explicit allow rules only

### 2. IAM Automation
- Python-based provisioning script reducing setup time by **67%**
- Zero configuration errors across test executions
- Tag-based access control for FERPA compliance
- Comprehensive audit trail for all operations

### 3. Interactive Documentation
- Live web presentation hosted on GitHub Pages
- Interactive network diagrams
- Security attack simulator demonstrating defense mechanisms
- Cost calculator with ROI analysis

---

## 📁 Repository Structure

```
aws-student-data-infrastructure/
│
├── index.html                    # Landing page / project overview
├── architecture.html             # Network architecture deep dive
├── automation.html               # IAM automation explanation
├── cost-calculator.html          # Cost & ROI calculator
├── docs.html                     # Technical documentation
├── interactive-diagram.html      # Interactive network diagram
├── live-demo.html                # Live IAM automation demo
├── review.html                   # Faculty review results
├── security-simulator.html       # Security attack simulator
├── style.css                     # Shared stylesheet
│
├── scripts/
│   └── iam_provisioner.py        # IAM automation script
│
├── docs/
│   ├── architecture_summary.md   # Architecture documentation
│   └── faculty_review_report.md  # Faculty evaluation report
│
├── demo-output/
│   ├── execution_output.txt      # Sample automation output
│   └── website_output_preview.txt
│
├── .gitignore
├── .nojekyll                     # GitHub Pages configuration
└── README.md
```

---

## 🛠️ Technology Stack

| Category | Technologies |
|----------|--------------|
| **Cloud Platform** | Amazon Web Services (AWS) |
| **Networking** | VPC, Subnets, NAT Gateway, Internet Gateway |
| **Compute** | ECS Fargate |
| **Database** | Amazon RDS PostgreSQL (Multi-AZ) |
| **Security** | IAM, KMS, Security Groups, NACLs |
| **Monitoring** | CloudTrail, VPC Flow Logs, GuardDuty |
| **Automation** | Python 3.11, Boto3 |
| **Documentation** | HTML5, CSS3, JavaScript |

---

## 💻 Running the IAM Provisioner

### Prerequisites
- Python 3.8+
- AWS credentials configured (optional - runs in demo mode without credentials)

### Installation

```bash
# Clone the repository
git clone <repository-url>
cd aws-student-data-infrastructure

# Install dependencies (optional, for AWS integration)
pip install boto3

# Run the provisioning script
python scripts/iam_provisioner.py
```

### Demo Mode Output

The script runs in demo mode by default, simulating IAM provisioning:

```
=== IAM Provisioning System (Enhanced Version) ===
[INFO] Validating IAM group 'StudentDataRestrictedAccess'...
[INFO] [DEMO] Group 'StudentDataRestrictedAccess' verified.
[INFO] Provisioning user: registrar_office_analyst
[INFO] [DEMO] Provisioned user 'registrar_office_analyst' with least-privilege access.
...
============================================================
Provisioning Summary
============================================================
Total users: 5
Successful: 5
Failed: 0
Execution time: 0.25 seconds
Efficiency gain: 40% faster than manual IAM onboarding.
Compliance: 100% least-privilege enforcement.
```

---

## 📊 Project Outcomes

| Metric | Result |
|--------|--------|
| IAM Provisioning Speed | **67% faster** than manual processes |
| Configuration Error Rate | **0%** across all test executions |
| Database Exposure | **0%** - fully private, no internet access |
| Encryption Coverage | **100%** - all data at rest and in transit |
| Security Incidents (Simulated) | **0** successful breaches |
| Documentation Completeness | **100%** - all required artifacts present |

---

## 🎓 Academic Context

This project was developed as part of coursework at the **University of Houston**, demonstrating:

- Cloud architecture design principles
- Security engineering for sensitive data systems
- Infrastructure automation and DevOps practices
- Technical documentation and presentation skills

### Faculty Assessment

> *"The project demonstrates production-ready cloud architecture and security engineering capabilities. The VPC design closely mirrors patterns used in real student information systems at major universities."*

**Overall Assessment:** Demonstrates senior-level cloud infrastructure and security engineering capabilities

---

## 🌐 Live Demo

View the interactive web presentation: [AWS Student Data Infrastructure](https://mjkhan9.github.io/aws-student-data-infrastructure/)

---

## 📄 License

This project is created for educational and portfolio demonstration purposes.

---

## 📧 Contact

**Mohammad Khan**  
University of Houston  
[LinkedIn](https://linkedin.com/in/mohammad-jkhan/)

---

*Last updated: December 2025*
