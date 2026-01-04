module "s3-bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.9.1"

  bucket = local.bucket_name

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  website = {
    index_document = "index.html"
  }

  versioning = {
    enabled = true
  }

  attach_policy = true
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "arn:aws:s3:::${local.bucket_name}/*"
      }
    ]
  })
}

resource "aws_s3_object" "frontend_files" {
  for_each = {
    for f in fileset("${path.module}/../frontend/", "**") : f => f
    if f != "config.js"
  }

  bucket       = module.s3-bucket.s3_bucket_id
  key          = each.value
  source       = "${path.module}/../frontend/${each.value}"
  content_type = lookup(local.mime_types, regex("\\.[^.]+$", each.value), "text/plain")
  depends_on   = [module.s3-bucket]
}

resource "aws_s3_object" "config_js" {
  bucket       = module.s3-bucket.s3_bucket_id
  key          = "config.js"
  content_type = "application/javascript"

  content = templatefile("${path.module}/../frontend/config.js", {
    user_pool_id = aws_cognito_user_pool.pool.id
    client_id    = aws_cognito_user_pool_client.client.id
    api_url      = aws_api_gateway_stage.prod.invoke_url
    region       = var.region
  })

  depends_on = [
    module.s3-bucket,
    aws_api_gateway_stage.prod
  ]
}
