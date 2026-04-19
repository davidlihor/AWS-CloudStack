output "s3_data_bucket_id" {
  description = "The ID of the S3 data bucket"
  value       = module.s3_data.s3_bucket_id
}

output "s3_data_bucket_arn" {
  description = "The ARN of the S3 data bucket"
  value       = module.s3_data.s3_bucket_arn
}

output "s3_data_bucket_regional_domain_name" {
  description = "The regional domain name of the S3 data bucket"
  value       = module.s3_data.s3_bucket_bucket_regional_domain_name
}

output "cloudfront_origin_access_control_id" {
  description = "The ID of the CloudFront Origin Access Control for S3"
  value       = aws_cloudfront_origin_access_control.s3_oac.id
}

output "dynamodb_table_name" {
  description = "The name of the DynamoDB table"
  value       = aws_dynamodb_table.cloudstack_table.name
}

output "dynamodb_table_arn" {
  description = "The ARN of the DynamoDB table"
  value       = aws_dynamodb_table.cloudstack_table.arn
}
