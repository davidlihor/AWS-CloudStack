locals {
  api_methods = {
    "POST_tasks"    = { res = aws_api_gateway_resource.tasks.id, method = "POST", lambda = "create_task" }
    "GET_tasks"     = { res = aws_api_gateway_resource.tasks.id, method = "GET", lambda = "get_tasks" }
    "PUT_taskId"    = { res = aws_api_gateway_resource.task_id.id, method = "PUT", lambda = "update_task" }
    "DELETE_taskId" = { res = aws_api_gateway_resource.task_id.id, method = "DELETE", lambda = "delete_task" }
    "POST_upload"   = { res = aws_api_gateway_resource.upload_url.id, method = "POST", lambda = "get_upload_url" }
    "GET_access"    = { res = aws_api_gateway_resource.get_access.id, method = "GET", lambda = "signer" }
  }

  cors_resources = {
    "api"        = aws_api_gateway_resource.api.id
    "tasks"      = aws_api_gateway_resource.tasks.id
    "taskId"     = aws_api_gateway_resource.task_id.id
    "upload_url" = aws_api_gateway_resource.upload_url.id
    "get_access" = aws_api_gateway_resource.get_access.id
  }

  secrets_extension_arn = "arn:aws:lambda:${var.region}:177933569100:layer:AWS-Parameters-and-Secrets-Lambda-Extension:12"
  resizer_layer_arn     = "arn:aws:lambda:${var.region}:770693421928:layer:Klayers-p312-Pillow:10"
}