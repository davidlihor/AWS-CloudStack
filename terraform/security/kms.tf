resource "aws_kms_key" "cloudfront_signer" {
  description              = "KMS Key for CloudFront Signing"
  customer_master_key_spec = "RSA_2048"
  key_usage                = "SIGN_VERIFY"
}

data "aws_kms_public_key" "pub" {
  key_id = aws_kms_key.cloudfront_signer.id
}

resource "aws_kms_key" "backup_key" {
  count                   = var.is_production ? 1 : 0
  description             = "KMS Key for encrypting DynamoDB backups"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

resource "aws_kms_alias" "backup_key_alias" {
  count         = var.is_production ? 1 : 0
  name          = "alias/${var.project_name}-backup-key"
  target_key_id = aws_kms_key.backup_key[0].key_id
}

resource "aws_kms_key" "secrets" {
  description             = "KMS key for Secrets Manager encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name = "${var.project_name}-secrets-key"
  }
}

resource "aws_kms_alias" "secrets" {
  name          = "alias/${var.project_name}-secrets"
  target_key_id = aws_kms_key.secrets.key_id
}

resource "aws_kms_key" "macie_key" {
  description             = "KMS key for Macie discovery results"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          "AWS" = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow Macie to use the key"
        Effect = "Allow"
        Principal = {
          "Service" = "macie.amazonaws.com"
        }
        Action = [
          "kms:GenerateDataKey",
          "kms:Encrypt"
        ]
        Resource = "*"
      }
    ]
  })
}
