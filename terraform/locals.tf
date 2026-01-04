locals {
  lambda_names = [
    "create_task",
    "get_tasks",
    "update_task",
    "delete_task"
  ]

  bucket_name = "cloudstack-project-${random_string.suffix.result}"

  mime_types = {
    ".html" = "text/html"
    ".css"  = "text/css"
    ".js"   = "application/javascript"
    ".json" = "application/json"
    ".png"  = "image/png"
    ".jpg"  = "image/jpeg"
    ".jpeg" = "image/jpeg"
    ".svg"  = "image/svg+xml"
    ".ico"  = "image/x-icon"
  }

  api_methods = {
    "POST_tasks"    = { res = aws_api_gateway_resource.tasks.id, method = "POST", lambda = "create_task" }
    "GET_tasks"     = { res = aws_api_gateway_resource.tasks.id, method = "GET", lambda = "get_tasks" }
    "PUT_taskId"    = { res = aws_api_gateway_resource.task_id.id, method = "PUT", lambda = "update_task" }
    "DELETE_taskId" = { res = aws_api_gateway_resource.task_id.id, method = "DELETE", lambda = "delete_task" }
  }

  cors_resources = {
    "tasks"  = aws_api_gateway_resource.tasks.id
    "taskId" = aws_api_gateway_resource.task_id.id
  }
}

