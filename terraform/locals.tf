locals {
  lambda_configs = {
    "create_task"    = { timeout = 3, memory = 128, needs_s3_write = false, needs_dynamo = true }
    "get_tasks"      = { timeout = 3, memory = 128, needs_s3_write = false, needs_dynamo = true }
    "update_task"    = { timeout = 3, memory = 128, needs_s3_write = false, needs_dynamo = true }
    "delete_task"    = { timeout = 3, memory = 128, needs_s3_write = false, needs_dynamo = true, needs_sqs = true }
    "get_upload_url" = { timeout = 3, memory = 128, needs_s3_write = true, needs_dynamo = true }
    "resizer"        = { timeout = 30, memory = 1024, needs_s3_read = true, needs_s3_write = true, needs_dynamo = true }
    "signer"         = { timeout = 3, memory = 128, needs_s3_write = false, needs_dynamo = false }
    "cleanup_task"   = { timeout = 30, memory = 256, needs_s3_delete = true, needs_dynamo = true }
  }

  s3_suffix = "-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}-an"

  bucket_name   = lower("${var.project_name}-project${local.s3_suffix}")
  bucket_data   = lower("${var.project_name}-data${local.s3_suffix}")
  bucket_config = lower("${var.project_name}-config${local.s3_suffix}")
}
