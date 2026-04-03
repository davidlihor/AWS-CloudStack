module "s3_data" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.11.0"

  bucket = local.bucket_data
  force_destroy = !var.production

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  versioning = { enabled = true }

  cors_rule = [{
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "POST", "GET"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }]
}

resource "aws_cloudfront_origin_access_control" "s3_oac" {
  name                              = "s3-data-oac"
  description                       = "Secure access control for S3 data"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_s3_bucket_policy" "allow_access_from_cloudfront" {
  bucket = module.s3_data.s3_bucket_id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipal"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action    = "s3:GetObject"
        Resource  = "${module.s3_data.s3_bucket_arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.s3_distribution.arn
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_notification" "s3_eventbridge_notify" {
  bucket      = module.s3_data.s3_bucket_id
  eventbridge = true
}
