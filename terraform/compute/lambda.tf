data "archive_file" "lambda_zip" {
  for_each    = var.lambda_configs
  type        = "zip"
  source_dir  = "${path.module}/../../lambda-functions"
  output_path = "${path.module}/../files/${each.key}.zip"

  excludes = setsubtract(
    fileset("${path.module}/../../lambda-functions", "*.py"),
    ["${each.key}.py", "config_helper.py"]
  )
}

resource "aws_lambda_function" "cloudstack_lambdas" {
  for_each = var.lambda_configs

  function_name = "${var.project_name}-${each.key}"
  role          = var.lambda_role_arns[each.key]
  handler       = "${each.key}.lambda_handler"
  runtime       = "python3.12"
  architectures = ["x86_64"]

  memory_size = each.value.memory
  timeout     = each.value.timeout

  reserved_concurrent_executions = each.key == "resizer" && var.is_production ? var.resizer_reserved_concurrency : null

  layers = compact([
    local.secrets_extension_arn,
    each.key == "resizer" ? local.resizer_layer_arn : null
  ])

  filename         = data.archive_file.lambda_zip[each.key].output_path
  source_code_hash = data.archive_file.lambda_zip[each.key].output_base64sha256

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_sg_id]
  }

  environment {
    variables = merge({
      PARAMETERS_SECRETS_EXTENSION_CACHE_ENABLED = "true"
      PARAMETERS_SECRETS_EXTENSION_CACHE_SIZE    = "100"
      SSM_PARAMETER_STORE_TTL                    = "300"
      SECRETS_MANAGER_TTL                        = "300"
      PARAMETERS_SECRETS_EXTENSION_LOG_LEVEL     = "INFO"

      SSM_PARAMETER_PREFIX  = "/${var.project_name}/${var.environment}"
      SECRET_ARN_CLOUDFRONT = var.cloudfront_secret_arn
      BUCKET_NAME           = var.s3_data_bucket_id
      }, each.key == "delete_task" ? {
      DELETE_QUEUE_URL_PARAM = "/${var.project_name}/${var.environment}/sqs/delete-queue-url"
    } : {})
  }
}

resource "aws_cloudwatch_log_group" "lambda" {
  for_each = var.lambda_configs

  name              = "/aws/lambda/CloudStack-${each.key}"
  retention_in_days = 30
}

resource "aws_lambda_permission" "apigw_lambda" {
  for_each = { for k, v in aws_lambda_function.cloudstack_lambdas : k => v if k != "resizer" }

  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = each.value.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}
