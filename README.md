# AWS Student Data Infrastructure  
Secure Three-Tier Architecture for Academic Data

This project designs and documents a secure, highly available AWS environment for student/academic data. It was built as a portfolio project to demonstrate cloud architecture, security engineering, IAM automation, and documentation skills using AWS services.

The repository backs a multi-page static site deployed via GitHub Pages that walks through the design, security controls, attack modeling, costs, and IAM automation concepts.

---

## 1. Project Overview

**Goal:** Provide a secure, auditable, and cost-aware cloud environment where a university or school could host student data and related applications.

**Key themes:**

- Defense-in-depth network design (three-tier VPC)
- Strong data protection (encryption, private networking, least privilege)
- Centralized logging and monitoring
- IAM automation and governance concepts
- Clear, reviewer-friendly documentation

This is a **learning/portfolio project**, not a production implementation. It focuses on design, patterns, and documentation, while leaving space for future infrastructure-as-code and automation.

---

## 2. High-Level Architecture

The environment is based on a classic **three-tier VPC**:

- **Public / Admin Tier**
  - Bastion/admin access
  - Entry point for operations and management traffic
  - Internet Gateway for controlled outbound access

- **Private / Application Tier**
  - Application services (APIs, web app backend, scheduled jobs)
  - No direct inbound internet access
  - Outbound access via NAT Gateway for patching and updates

- **Private / Database Tier**
  - Amazon RDS for relational student/academic data
  - Subnets with no direct route to the internet
  - Access limited to application tier via security groups

**Security & Observability Layers (by design):**

- VPC, Subnets, Route Tables
- NAT Gateway for egress from private tiers
- Security Groups and NACLs to limit traffic between tiers
- AWS KMS for key management and encryption
- AWS CloudTrail and S3 for audit logs
- VPC Flow Logs for network visibility
- (Designed to integrate with GuardDuty/WAF for additional protection)

---

## 3. Features by Page

The GitHub Pages site presents the project in several focused sections:

### 3.1 Landing / Overview (`index.html`)

- High-level description of the project and problem space
- Explanation of goals: secure student data, strong logging, IAM governance
- Links to deep-dive pages (architecture, documentation, cost, security, demo)

### 3.2 Architecture Deep Dive (`architecture.html` or similar)

- Visual + textual breakdown of:
  - VPC CIDR and subnets
  - Public vs private tiers
  - Routing between app and DB layers
  - RDS placement and access paths
- Explanation of why the environment is structured this way (admin isolation, DB isolation, reduced blast radius, etc.)

### 3.3 Documentation (`docs.html` / `architecture_summary.md`)

- Written narrative of:
  - Design decisions
  - Security requirements
  - HA and DR considerations
  - Logging and auditing strategy
- Suitable as an internal architecture/design doc for a small cloud team

### 3.4 Cost & ROI Calculator (`cost-calculator.html`)

- Conceptual cost breakdown of core components:
  - VPC + NAT Gateway
  - RDS
  - Logging and audit pipeline (CloudTrail, Flow Logs, S3)
  - Application compute layer
- Discusses:
  - How architecture decisions impact cost
  - Ideas for cost optimization (RIs/Savings Plans, S3 storage classes, VPC endpoints, etc.)
- Designed as an educational tool to think about **cost vs. security** tradeoffs

### 3.5 Security Attack Simulator (`security-simulator.html`)

- Lists common attack paths against student data environments, such as:
  - Direct database access from the internet
  - Lateral movement between subnets
  - IAM privilege escalation
  - Public S3 bucket exposure
  - Unencrypted access paths
- For each attack pattern, explains:
  - Which layer(s) would stop it in this design (SGs, NACLs, KMS, private subnets, logging)
  - Why the attack fails in this architecture
- Acts as a “threat modeling” visualization for the environment

### 3.6 Interactive Network Diagram (`interactive-diagram.html`)

- Visual representation of:
  - VPC, subnets, CIDRs
  - Internet Gateway, NAT Gateway
  - RDS, app tier, admin entry points
  - Logging endpoints, S3 buckets, KMS
- Helps non-cloud stakeholders understand how traffic flows and where security boundaries exist

### 3.7 Live IAM Automation Demo (`live-demo.html`)

- Front-end demo that **simulates**:
  - Provisioning IAM-style identities
  - Assigning roles/policies
  - Logging actions to an “audit trail”
- Backed by a sample Python script in the repo to illustrate how IAM provisioning could be automated in a real environment

### 3.8 Faculty Review & Outcomes (`faculty_review_report.md` / dedicated HTML)

- Summarizes a mock or real academic review of the project:
  - Network Architecture, Security Controls, Automation Quality, Documentation
- Shows which areas **Meet** vs **Exceed** expectations
- Explicitly calls out skills demonstrated:
  - VPC design
  - Security engineering
  - Infrastructure/identity automation concepts
  - Technical documentation

---

## 4. IAM Automation (Conceptual)

The repo includes a sample script (e.g., `iam_provisioner.py`) to illustrate:

- How a pipeline could:
  - Read in user definitions
  - Apply least-privilege roles/policies
  - Enforce naming and tagging standards
  - Log provisioning/deprovisioning events
- It is intentionally minimal and meant as a **starting point** or teaching example, not a production-ready IAM system.

---

## 5. Repository Structure

Exact filenames may vary slightly, but the repo is organized roughly as:

```text
aws-student-data-infrastructure/
├── index.html                    # Landing page / project overview
├── architecture.html             # Network architecture deep dive
├── docs.html                     # Detailed documentation view
├── cost-calculator.html          # Cost & ROI educational page
├── security-simulator.html       # Security attack simulation page
├── interactive-diagram.html      # Network diagram view
├── live-demo.html                # Live IAM automation demo (front-end)
├── iam_provisioner.py            # Sample IAM automation script (conceptual)
├── architecture_summary.md       # Text version of architecture explanation
├── faculty_review_report.md      # Faculty review & outcomes summary
├── assets/                       # CSS, JS, images, icons
│   ├── css/
│   ├── js/
│   └── img/
└── README.md                     # You are here
