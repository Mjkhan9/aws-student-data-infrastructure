#===============================================================================
# IAM - Identity and Access Management Policies
#===============================================================================
# Implements MFA enforcement, least privilege, and security guardrails
# These policies work in conjunction with the Python provisioning script
#===============================================================================

#-------------------------------------------------------------------------------
# IAM Group for Student Data Access
#-------------------------------------------------------------------------------

resource "aws_iam_group" "student_data_access" {
  name = "StudentDataRestrictedAccess"
  path = "/student-data/"
}

#-------------------------------------------------------------------------------
# MFA Enforcement Policy
#-------------------------------------------------------------------------------
# Denies ALL actions unless MFA is present
# Users must authenticate with MFA to perform any operation

resource "aws_iam_policy" "mfa_enforcement" {
  name        = "${var.project_name}-mfa-enforcement"
  description = "Enforces MFA for all actions except managing own MFA device"
  path        = "/security/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowViewAccountInfo"
        Effect = "Allow"
        Action = [
          "iam:GetAccountPasswordPolicy",
          "iam:ListVirtualMFADevices"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowManageOwnVirtualMFADevice"
        Effect = "Allow"
        Action = [
          "iam:CreateVirtualMFADevice",
          "iam:DeleteVirtualMFADevice"
        ]
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:mfa/$${aws:username}"
      },
      {
        Sid    = "AllowManageOwnMFA"
        Effect = "Allow"
        Action = [
          "iam:DeactivateMFADevice",
          "iam:EnableMFADevice",
          "iam:ListMFADevices",
          "iam:ResyncMFADevice"
        ]
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/$${aws:username}"
      },
      {
        Sid    = "AllowManageOwnAccessKeys"
        Effect = "Allow"
        Action = [
          "iam:CreateAccessKey",
          "iam:DeleteAccessKey",
          "iam:ListAccessKeys",
          "iam:UpdateAccessKey",
          "iam:GetAccessKeyLastUsed"
        ]
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/$${aws:username}"
        Condition = {
          Bool = {
            "aws:MultiFactorAuthPresent" = "true"
          }
        }
      },
      {
        Sid    = "AllowManageOwnPassword"
        Effect = "Allow"
        Action = [
          "iam:ChangePassword",
          "iam:GetUser"
        ]
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/$${aws:username}"
      },
      {
        Sid    = "DenyAllExceptListedIfNoMFA"
        Effect = "Deny"
        NotAction = [
          "iam:CreateVirtualMFADevice",
          "iam:EnableMFADevice",
          "iam:GetUser",
          "iam:ChangePassword",
          "iam:ListMFADevices",
          "iam:ListVirtualMFADevices",
          "iam:ResyncMFADevice",
          "sts:GetSessionToken",
          "iam:GetAccountPasswordPolicy"
        ]
        Resource = "*"
        Condition = {
          BoolIfExists = {
            "aws:MultiFactorAuthPresent" = "false"
          }
        }
      }
    ]
  })

  tags = {
    Name       = "${var.project_name}-mfa-enforcement"
    Purpose    = "Security policy requiring MFA"
    Compliance = "FERPA"
  }
}

# Attach MFA enforcement to the student data access group
resource "aws_iam_group_policy_attachment" "mfa_enforcement" {
  group      = aws_iam_group.student_data_access.name
  policy_arn = aws_iam_policy.mfa_enforcement.arn
}

#-------------------------------------------------------------------------------
# S3 Read-Only Policy for Student Data
#-------------------------------------------------------------------------------
# Allows read-only access to student data buckets
# Requires specific resource tags for access (tag-based access control)

resource "aws_iam_policy" "student_data_s3_readonly" {
  name        = "${var.project_name}-s3-readonly"
  description = "Read-only access to student data S3 buckets with tag-based restrictions"
  path        = "/student-data/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ListAllBuckets"
        Effect = "Allow"
        Action = [
          "s3:ListAllMyBuckets",
          "s3:GetBucketLocation"
        ]
        Resource = "*"
      },
      {
        Sid    = "ListStudentDataBucket"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketTagging"
        ]
        Resource = "arn:aws:s3:::${var.project_name}-*"
        Condition = {
          StringEquals = {
            "s3:ResourceTag/DataClassification" = "StudentData"
          }
        }
      },
      {
        Sid    = "ReadStudentDataObjects"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectTagging",
          "s3:GetObjectVersion"
        ]
        Resource = "arn:aws:s3:::${var.project_name}-*/*"
        Condition = {
          StringEquals = {
            "s3:ExistingObjectTag/DataClassification" = "StudentData"
          }
        }
      },
      {
        Sid    = "DenyPublicBucketAccess"
        Effect = "Deny"
        Action = [
          "s3:PutBucketPublicAccessBlock",
          "s3:DeletePublicAccessBlock"
        ]
        Resource = "*"
      },
      {
        Sid    = "DenyUnencryptedUploads"
        Effect = "Deny"
        Action = "s3:PutObject"
        Resource = "*"
        Condition = {
          Null = {
            "s3:x-amz-server-side-encryption" = "true"
          }
        }
      }
    ]
  })

  tags = {
    Name       = "${var.project_name}-s3-readonly"
    Purpose    = "Student data read access"
    Compliance = "FERPA"
  }
}

# Attach S3 read-only policy to the student data access group
resource "aws_iam_group_policy_attachment" "student_data_s3_readonly" {
  group      = aws_iam_group.student_data_access.name
  policy_arn = aws_iam_policy.student_data_s3_readonly.arn
}

#-------------------------------------------------------------------------------
# Deny Dangerous Actions Policy
#-------------------------------------------------------------------------------
# Explicitly denies dangerous actions that could compromise security

resource "aws_iam_policy" "deny_dangerous_actions" {
  name        = "${var.project_name}-deny-dangerous"
  description = "Explicitly denies dangerous actions for student data users"
  path        = "/security/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyIAMChanges"
        Effect = "Deny"
        Action = [
          "iam:CreateUser",
          "iam:DeleteUser",
          "iam:CreateGroup",
          "iam:DeleteGroup",
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:AttachUserPolicy",
          "iam:AttachGroupPolicy",
          "iam:AttachRolePolicy",
          "iam:PutUserPolicy",
          "iam:PutGroupPolicy",
          "iam:PutRolePolicy",
          "iam:CreatePolicyVersion",
          "iam:SetDefaultPolicyVersion"
        ]
        Resource = "*"
      },
      {
        Sid    = "DenySecurityGroupChanges"
        Effect = "Deny"
        Action = [
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupEgress",
          "ec2:DeleteSecurityGroup",
          "ec2:CreateSecurityGroup"
        ]
        Resource = "*"
      },
      {
        Sid    = "DenyNetworkChanges"
        Effect = "Deny"
        Action = [
          "ec2:CreateVpc",
          "ec2:DeleteVpc",
          "ec2:CreateSubnet",
          "ec2:DeleteSubnet",
          "ec2:CreateInternetGateway",
          "ec2:AttachInternetGateway",
          "ec2:CreateNatGateway",
          "ec2:DeleteNatGateway"
        ]
        Resource = "*"
      },
      {
        Sid    = "DenyKMSKeyDeletion"
        Effect = "Deny"
        Action = [
          "kms:ScheduleKeyDeletion",
          "kms:DisableKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "DenyCloudTrailChanges"
        Effect = "Deny"
        Action = [
          "cloudtrail:DeleteTrail",
          "cloudtrail:StopLogging",
          "cloudtrail:UpdateTrail"
        ]
        Resource = "*"
      },
      {
        Sid    = "DenyRDSPublicAccess"
        Effect = "Deny"
        Action = "rds:ModifyDBInstance"
        Resource = "*"
        Condition = {
          Bool = {
            "rds:PubliclyAccessible" = "true"
          }
        }
      }
    ]
  })

  tags = {
    Name       = "${var.project_name}-deny-dangerous"
    Purpose    = "Security guardrails"
    Compliance = "FERPA"
  }
}

# Attach deny dangerous actions policy to the student data access group
resource "aws_iam_group_policy_attachment" "deny_dangerous_actions" {
  group      = aws_iam_group.student_data_access.name
  policy_arn = aws_iam_policy.deny_dangerous_actions.arn
}

#-------------------------------------------------------------------------------
# IAM Password Policy (Account-Level)
#-------------------------------------------------------------------------------

resource "aws_iam_account_password_policy" "strict" {
  minimum_password_length        = 14
  require_lowercase_characters   = true
  require_uppercase_characters   = true
  require_numbers                = true
  require_symbols                = true
  allow_users_to_change_password = true
  max_password_age               = 90
  password_reuse_prevention      = 24
  hard_expiry                    = false
}

