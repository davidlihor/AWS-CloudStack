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

resource "aws_sfn_state_machine" "task_cleanup_sfn" {
  name     = "TaskCleanupWorkflow"
  role_arn = aws_iam_role.lambda_roles["cleanup_task"].arn

  definition = jsonencode({
    Comment = "Enterprise Task Cleanup with Parallel Execution and Error Handling",
    StartAt = "ValidateInput",
    States = {
      ValidateInput = {
        Type = "Pass",
        Parameters = {
          "body.$" = "States.StringToJson($[0].body)",
          "timestamp.$" = "$$.State.EnteredTime"
        },
        Next = "ExtractPayload"
      },
      ExtractPayload = {
        Type = "Pass",
        Parameters = {
          "userId.$" = "$.body.userId",
          "taskId.$" = "$.body.taskId",
          "timestamp.$" = "$.timestamp"
        },
        Next = "ParallelCleanup"
      },
      ParallelCleanup = {
        Type = "Parallel",
        Branches = [
          {
            StartAt = "DeleteDynamoDB",
            States = {
              DeleteDynamoDB = {
                Type = "Task",
                Resource = aws_lambda_function.cloudstack_lambdas["cleanup_task"].arn,
                Parameters = {
                  "action" = "delete_dynamodb",
                  "userId.$" = "$.userId",
                  "taskId.$" = "$.taskId"
                },
                Catch = [
                  {
                    ErrorEquals = ["States.TaskFailed"],
                    ResultPath = "$.dynamo_error",
                    Next = "DynamoDBFailed"
                  }
                ],
                End = true
              },
              DynamoDBFailed = {
                Type = "Pass",
                Parameters = {
                  "status" = "DYNAMODB_DELETE_FAILED",
                  "error.$" = "$.dynamo_error"
                },
                End = true
              }
            }
          },
          {
            StartAt = "DeleteS3Objects",
            States = {
              DeleteS3Objects = {
                Type = "Task",
                Resource = aws_lambda_function.cloudstack_lambdas["cleanup_task"].arn,
                Parameters = {
                  "action" = "delete_s3",
                  "userId.$" = "$.userId",
                  "taskId.$" = "$.taskId"
                },
                Catch = [
                  {
                    ErrorEquals = ["States.TaskFailed"],
                    ResultPath = "$.s3_error",
                    Next = "S3DeleteFailed"
                  }
                ],
                End = true
              },
              S3DeleteFailed = {
                Type = "Pass",
                Parameters = {
                  "status" = "S3_DELETE_FAILED",
                  "error.$" = "$.s3_error"
                },
                End = true
              }
            }
          }
        ],
        Next = "EvaluateResults",
        Catch = [
          {
            ErrorEquals = ["States.ALL"],
            ResultPath = "$.error",
            Next = "CleanupFailed"
          }
        ]
      },
      EvaluateResults = {
        Type = "Pass",
        Parameters = {
          "status" = "SUCCESS",
          "userId.$" = "$.[0].userId",
          "taskId.$" = "$.[0].taskId",
          "dynamoResult.$" = "$.[0]",
          "s3Result.$" = "$.[1]",
          "completedAt.$" = "$$.State.EnteredTime"
        },
        End = true
      },
      CleanupFailed = {
        Type = "Task",
        Resource = aws_lambda_function.cloudstack_lambdas["cleanup_task"].arn,
        Parameters = {
          "action" = "log_failure",
          "error.$" = "$.error",
          "userId.$" = "$.userId",
          "taskId.$" = "$.taskId"
        },
        Next = "SendToDLQ"
      },
      SendToDLQ = {
        Type = "Task",
        Resource = "arn:aws:states:::sqs:sendMessage",
        Parameters = {
          "QueueUrl" = aws_sqs_queue.task_deletion_dlq.id,
          "MessageBody" = {
            "error.$" = "$.error",
            "userId.$" = "$.userId",
            "taskId.$" = "$.taskId",
            "timestamp.$" = "$$.State.EnteredTime"
          }
        },
        End = true
      }
    }
  })
}
