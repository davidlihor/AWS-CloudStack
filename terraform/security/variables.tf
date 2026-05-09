variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
}

variable "region" {
  description = "AWS region where resources will be created"
  type        = string
}

variable "is_production" {
  description = "Flag to indicate production environment"
  type        = bool
}

variable "lambda_configs" {
  description = "Map of Lambda function configurations"
  type        = any
}

variable "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table for IAM policies"
  type        = string
}

variable "s3_data_bucket_arn" {
  description = "ARN of the S3 data bucket for IAM policies"
  type        = string
}

variable "s3_data_bucket_id" {
  description = "ID of the S3 data bucket for GuardDuty malware protection"
  type        = string
}

variable "sqs_queue_arns" {
  description = "Map of SQS queue ARNs"
  type = object({
    task_deletion_queue_arn    = string
    task_deletion_dlq_arn      = string
    image_processing_queue_arn = string
  })
}

variable "lambda_function_arns" {
  description = "Map of Lambda function ARNs for IAM policies"
  type        = map(string)
  default     = {}
}

variable "budget_limit" {
  description = "Monthly budget limit in USD for cost alerts"
  type        = number
  default     = 100
}

variable "budget_alert_emails" {
  description = "List of email addresses to receive budget alerts"
  type        = list(string)
  default     = []
}

variable "bucket_config_name" {
  description = "Name of the S3 bucket for AWS Config logs"
  type        = string
}

variable "kms_public_key" {
  description = "Public key from KMS for CloudFront signing (optional)"
  type        = string
  default     = ""
}

variable "cloudfront_secret_arn" {
  description = "ARN of the CloudFront key ID secret for IAM policies"
  type        = string
}

variable "kms_key_secrets_arn" {
  description = "ARN of the KMS key for Secrets Manager encryption (for IAM policies)"
  type        = string
}

variable "cloudfront_public_key_id" {
  description = "ID of the CloudFront public key for URL signing (from frontend module)"
  type        = string
}
