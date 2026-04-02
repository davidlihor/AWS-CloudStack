resource "aws_sfn_state_machine" "image_processor_sfn" {
  name     = "ImageProcessingWorkflow"
  role_arn = aws_iam_role.lambda_roles["resizer"].arn
  
  definition = jsonencode({
    StartAt = "ResizeImage",
    States = {
      ResizeImage = {
        Type     = "Task",
        Resource = aws_lambda_function.cloudstack_lambdas["resizer"].arn,
        End      = true
      }
    }
  })
}
