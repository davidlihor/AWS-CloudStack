resource "aws_backup_vault" "dynamodb_vault" {
  name = "${var.project_name}-backup-vault"
  kms_key_arn = aws_kms_key.backup_key.arn
}

resource "aws_backup_plan" "dynamodb_plan" {
  name = "${var.project_name}-backup-plan"

  rule {
    rule_name         = "daily-backup-90-days-retention"
    target_vault_name = aws_backup_vault.dynamodb_vault.name
    schedule          = "cron(0 12 * * ? *)"

    lifecycle {
      delete_after = 90
    }
  }
}

resource "aws_iam_role" "backup_role" {
  name = "${var.project_name}-backup-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "backup.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "backup_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
  role       = aws_iam_role.backup_role.name
}

resource "aws_iam_role_policy_attachment" "restore_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
  role       = aws_iam_role.backup_role.name
}

resource "aws_backup_selection" "dynamodb_selection" {
  iam_role_arn = aws_iam_role.backup_role.arn
  name         = "${var.project_name}-selection"
  plan_id      = aws_backup_plan.dynamodb_plan.id

  resources = [
    aws_dynamodb_table.cloudstack_table.arn
  ]
}