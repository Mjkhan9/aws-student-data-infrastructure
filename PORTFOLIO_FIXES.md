# Portfolio Fixes - Action Items

This document contains the specific changes needed across all your portfolio repositories.

## ✅ COMPLETED (aws-student-data-infrastructure)

The following fixes have been applied to this repository:

1. **iam_provisioner.py** - Updated to use `IAM_LIVE_MODE` environment variable instead of hardcoded `DEMO_MODE = True`
2. **docs/index.html** - Added GitHub links to author section and footer
3. **README.md** - Updated to reflect new environment variable approach

---

## 🔧 REQUIRED FIXES (Other Repositories)

### 1. Terraform-3-Tier-Web-Application

**File:** `docs/index.html`

**Issue:** Credly badge links contain placeholder URLs

**Current (BROKEN):**
```html
<a href="https://www.credly.com/badges/your-badge-id" target="_blank" class="cert-badge" title="AWS Solutions Architect - Associate">
    <img src="https://images.credly.com/size/340x340/images/0e284c3f-5164-4b21-8660-0d84737941bc/image.png" alt="AWS Solutions Architect Associate">
</a>
<a href="https://www.credly.com/badges/your-badge-id" target="_blank" class="cert-badge" title="AWS Cloud Practitioner">
    <img src="https://images.credly.com/size/340x340/images/00634f82-b07f-4bbd-a6bb-53de397fc3a6/image.png" alt="AWS Cloud Practitioner">
</a>
```

**Fix Option A - Remove links (show badges only):**
```html
<span class="cert-badge" title="AWS Solutions Architect - Associate">
    <img src="https://images.credly.com/size/340x340/images/0e284c3f-5164-4b21-8660-0d84737941bc/image.png" alt="AWS Solutions Architect Associate">
</span>
<span class="cert-badge" title="AWS Cloud Practitioner">
    <img src="https://images.credly.com/size/340x340/images/00634f82-b07f-4bbd-a6bb-53de397fc3a6/image.png" alt="AWS Cloud Practitioner">
</span>
```

**Fix Option B - Use your actual Credly badge URLs:**

1. Go to https://www.credly.com
2. Log in and find your AWS certifications
3. Click "Share" on each badge to get the actual URL
4. Replace `your-badge-id` with the real badge ID

---

### 2. Automated-IAM-User-Lifecycle-Management-System-Project

**File:** `index.html` (in the root or docs folder)

**Issue:** LinkedIn link inconsistency - uses `mjkhan1` instead of `mohammad-jkhan`

**Find and replace ALL instances of:**
```
linkedin.com/in/mjkhan1
```

**Replace with:**
```
linkedin.com/in/mohammad-jkhan
```

---

## 📝 GitHub Repository Settings

For each repository, add a description and topics in the GitHub settings:

### aws-student-data-infrastructure
- **Description:** Secure 3-tier AWS VPC architecture with IAM automation for student data systems. Built with Terraform and Python/Boto3.
- **Topics:** `aws`, `terraform`, `iam`, `vpc`, `python`, `boto3`, `security`, `cloud-infrastructure`, `devops`

### Terraform-3-Tier-Web-Application
- **Description:** Production-grade auto-scaling AWS infrastructure with 10 Terraform modules. Features VPC endpoints, RDS, ALB, and GitHub Actions CI/CD.
- **Topics:** `terraform`, `aws`, `infrastructure-as-code`, `alb`, `rds`, `autoscaling`, `github-actions`, `devops`

### Automated-IAM-User-Lifecycle-Management-System-Project
- **Description:** Hybrid IAM automation platform syncing Active Directory with AWS IAM using Flask and PowerShell.
- **Topics:** `iam`, `active-directory`, `aws`, `flask`, `powershell`, `identity-management`, `automation`

### aws-mfa-incident-simulator
- **Description:** MFA incident response simulator with dual-mode detection for CloudTrail events. Includes runbooks and remediation workflows.
- **Topics:** `aws`, `security`, `incident-response`, `cloudtrail`, `lambda`, `terraform`, `mfa`

---

## 🔗 Recommended Next Steps

1. **Clone each repository** and apply the fixes above
2. **Update GitHub repo settings** with descriptions and topics
3. **Get your actual Credly badge URLs** to fix the placeholder links
4. **Commit and push** all changes

---

*Generated: December 2025*

