data "archive_file" "lambda_zip" {
  for_each    = local.lambda_configs
  type        = "zip"
  source_file = "${path.module}/../lambda-functions/${each.key}.py"
  output_path = "${path.module}/files/${each.key}.zip"
}

resource "aws_lambda_function" "cloudstack_lambdas" {
  for_each      = local.lambda_configs
  
  function_name = "CloudStack-${each.key}"
  role          = aws_iam_role.lambda_roles[each.key].arn
  handler       = "${each.key}.lambda_handler"
  runtime       = "python3.12"

  memory_size      = each.value.memory
  timeout          = each.value.timeout

  layers           = each.key == "resizer" ? ["arn:aws:lambda:us-east-1:770693421928:layer:Klayers-p312-Pillow:7"] : []
  
  filename         = data.archive_file.lambda_zip[each.key].output_path
  source_code_hash = data.archive_file.lambda_zip[each.key].output_base64sha256

  environment {
    variables = merge({
      TABLE_NAME = aws_dynamodb_table.cloudstack_table.name
      BUCKET_NAME = module.s3_data.s3_bucket_id
      KMS_KEY_ID = aws_kms_key.cloudfront_signer.arn
      CLOUDFRONT_KEY_ID = aws_cloudfront_public_key.app_key.id
    }, each.key == "delete_task" ? {
      DELETE_QUEUE_URL = aws_sqs_queue.task_deletion_queue.id
    } : {})
  }
}

resource "aws_lambda_permission" "apigw_lambda" {
  for_each      = { for k, v in aws_lambda_function.cloudstack_lambdas : k => v if k != "resizer" }

  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = each.value.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}
