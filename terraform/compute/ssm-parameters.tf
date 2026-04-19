resource "aws_ssm_parameter" "table_name" {
  name  = "/${var.project_name}/${var.environment}/dynamodb/table-name"
  type  = "String"
  value = var.dynamodb_table_name
  tier  = "Standard"

  tags = {
    Name = "DynamoDB Table Name"
  }
}

resource "aws_ssm_parameter" "bucket_name" {
  name  = "/${var.project_name}/${var.environment}/s3/data-bucket"
  type  = "String"
  value = var.s3_data_bucket_id
  tier  = "Standard"

  tags = {
    Name = "S3 Data Bucket"
  }
}

resource "aws_ssm_parameter" "kms_key_id" {
  name   = "/${var.project_name}/${var.environment}/kms/cloudfront-signer-arn"
  type   = "SecureString"
  value  = var.kms_key_cloudfront_signer_arn
  key_id = var.kms_key_secrets_arn
  tier   = "Standard"

  tags = {
    Name = "KMS CloudFront Signer ARN"
  }
}

resource "aws_ssm_parameter" "delete_queue_url" {
  name  = "/${var.project_name}/${var.environment}/sqs/delete-queue-url"
  type  = "String"
  value = aws_sqs_queue.task_deletion_queue.id
  tier  = "Standard"

  tags = {
    Name = "SQS Delete Queue URL"
  }
}

resource "aws_ssm_parameter" "config_prefix" {
  name  = "/${var.project_name}/${var.environment}/config/prefix"
  type  = "String"
  value = "/${var.project_name}/${var.environment}"
  tier  = "Standard"
}
