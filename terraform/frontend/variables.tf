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

variable "domain_name" {
  description = "Primary domain name for ACM and CloudFront (null if not using custom domain)"
  type        = string
  default     = null
}

variable "bucket_name" {
  description = "Name of the S3 bucket for frontend hosting"
  type        = string
}

variable "cognito_user_pool_id" {
  description = "ID of the Cognito User Pool for config.js"
  type        = string
}

variable "cognito_user_pool_client_id" {
  description = "ID of the Cognito User Pool Client for config.js"
  type        = string
}

variable "s3_data_bucket_id" {
  description = "ID of the S3 data bucket for CloudFront origin"
  type        = string
}

variable "s3_data_bucket_regional_domain_name" {
  description = "Regional domain name of the S3 data bucket for CloudFront origin"
  type        = string
}

variable "api_gateway_stage_invoke_url" {
  description = "Invoke URL of the API Gateway stage"
  type        = string
}

variable "cloudfront_origin_access_control_id" {
  description = "ID of the CloudFront Origin Access Control for S3 data bucket"
  type        = string
}

variable "waf_acl_arn" {
  description = "ARN of the WAF Web ACL to associate with CloudFront"
  type        = string
}

variable "kms_key_cloudfront_signer_id" {
  description = "ID of the KMS key for CloudFront signing (used to fetch public key)"
  type        = string
}

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate for CloudFront HTTPS (from network module)"
  type        = string
  default     = null
}
