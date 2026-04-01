data "archive_file" "lambda_zip" {
  for_each    = toset(local.lambda_names)
  type        = "zip"
  source_file = "${path.module}/../lambda-functions/${each.value}.py"
  output_path = "${path.module}/files/${each.value}.zip"
}

resource "aws_lambda_function" "cloudstack_lambdas" {
  for_each      = toset(local.lambda_names)
  function_name = "CloudStack-${each.value}"
  role          = aws_iam_role.lambda_role.arn
  handler       = "${each.value}.lambda_handler"
  runtime       = "python3.12"

  filename         = data.archive_file.lambda_zip[each.value].output_path
  source_code_hash = data.archive_file.lambda_zip[each.value].output_base64sha256

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.cloudstack_table.name
      BUCKET_NAME = module.s3_data.s3_bucket_id
    }
  }
}

resource "aws_lambda_permission" "apigw_lambda" {
  for_each      = aws_lambda_function.cloudstack_lambdas
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = each.value.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

resource "aws_iam_role_policy" "lambda_upload_policy" {
  name = "lambda_upload_s3_dynamo_policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["dynamodb:GetItem"]
        Resource = aws_dynamodb_table.cloudstack_table.arn
      },
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject"]
        Resource = "${module.s3_data.s3_bucket_arn}/*"
      }
    ]
  })
}
