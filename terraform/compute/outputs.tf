# API Gateway
output "api_gateway_stage_invoke_url" {
  description = "Invoke URL of the API Gateway stage"
  value       = aws_api_gateway_stage.prod.invoke_url
}

output "api_gateway_execution_arn" {
  description = "Execution ARN of the API Gateway"
  value       = aws_api_gateway_rest_api.api.execution_arn
}

output "api_gateway_rest_api_id" {
  description = "ID of the API Gateway REST API"
  value       = aws_api_gateway_rest_api.api.id
}

# Lambda Functions
output "lambda_function_arns" {
  description = "Map of Lambda function names to their ARNs"
  value       = { for k, v in aws_lambda_function.cloudstack_lambdas : k => v.arn }
}

output "lambda_function_names" {
  description = "Map of Lambda function names to their function names"
  value       = { for k, v in aws_lambda_function.cloudstack_lambdas : k => v.function_name }
}

# SQS Queues
output "sqs_task_deletion_queue_arn" {
  description = "ARN of the task deletion SQS queue"
  value       = aws_sqs_queue.task_deletion_queue.arn
}

output "sqs_task_deletion_queue_url" {
  description = "URL of the task deletion SQS queue"
  value       = aws_sqs_queue.task_deletion_queue.id
}

output "sqs_task_deletion_dlq_arn" {
  description = "ARN of the task deletion DLQ"
  value       = aws_sqs_queue.task_deletion_dlq.arn
}

output "sqs_image_processing_queue_arn" {
  description = "ARN of the image processing SQS queue"
  value       = aws_sqs_queue.image_processing_queue.arn
}
