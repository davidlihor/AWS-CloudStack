resource "aws_api_gateway_rest_api" "api" {
  name = "CloudStackAPI"
}

resource "aws_api_gateway_authorizer" "cognito_auth" {
  name          = "CognitoAuthorizer"
  type          = "COGNITO_USER_POOLS"
  rest_api_id   = aws_api_gateway_rest_api.api.id
  provider_arns = [aws_cognito_user_pool.pool.arn]
  identity_source = "method.request.header.Authorization"
}

resource "aws_api_gateway_resource" "tasks" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "tasks"
}

resource "aws_api_gateway_resource" "task_id" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.tasks.id
  path_part   = "{taskId}"
}

locals {
  methods = {
    "POST_tasks"    = { res = aws_api_gateway_resource.tasks.id,   method = "POST",   lambda = "create_task" },
    "GET_tasks"     = { res = aws_api_gateway_resource.tasks.id,   method = "GET",    lambda = "get_tasks" },
    "PUT_taskId"    = { res = aws_api_gateway_resource.task_id.id, method = "PUT",    lambda = "update_task" },
    "DELETE_taskId" = { res = aws_api_gateway_resource.task_id.id, method = "DELETE", lambda = "delete_task" }
  }
}

resource "aws_api_gateway_method" "methods" {
  for_each      = local.methods
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = each.value.res
  http_method   = each.value.method
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito_auth.id
}

resource "aws_api_gateway_integration" "lambda_int" {
  for_each                = local.methods
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = each.value.res
  http_method             = aws_api_gateway_method.methods[each.key].http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.cloudstack_lambdas[each.value.lambda].invoke_arn
}

resource "aws_api_gateway_deployment" "prod" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_integration.lambda_int))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_method.methods, 
    aws_api_gateway_integration.lambda_int,
    aws_api_gateway_integration.options_mock
  ]
}

resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.prod.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = "prod"
}

resource "aws_s3_object" "config_js" {
  bucket       = module.s3-bucket.s3_bucket_id
  key          = "config.js"
  content_type = "application/javascript"

  content = templatefile("${path.module}/../frontend/config.js", {
    user_pool_id = aws_cognito_user_pool.pool.id
    client_id    = aws_cognito_user_pool_client.client.id
    api_url      = "${aws_api_gateway_stage.prod.invoke_url}"
    region       = var.region
  })
}

locals {
  cors_resources = {
    "tasks"   = aws_api_gateway_resource.tasks.id,
    "taskId"  = aws_api_gateway_resource.task_id.id
  }
}

resource "aws_api_gateway_method" "options" {
  for_each      = local.cors_resources
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = each.value
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options_mock" {
  for_each    = local.cors_resources
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = each.value
  http_method = aws_api_gateway_method.options[each.key].http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "options_200" {
  for_each    = local.cors_resources
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = each.value
  http_method = aws_api_gateway_method.options[each.key].http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "options_int_resp" {
  for_each    = local.cors_resources
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = each.value
  http_method = aws_api_gateway_method.options[each.key].http_method
  status_code = aws_api_gateway_method_response.options_200[each.key].status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'DELETE,GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}
