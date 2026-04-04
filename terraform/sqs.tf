resource "aws_sqs_queue" "task_deletion_dlq" {
  name = "cloudstack-task-deletion-dlq"
  message_retention_seconds = 1209600
}

resource "aws_sqs_queue" "task_deletion_queue" {
  name = "cloudstack-task-deletion-queue"
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.task_deletion_dlq.arn
    maxReceiveCount     = 3
  })
}

resource "aws_sqs_queue" "image_processing_queue" {
  name = "cloudstack-image-processing-queue"
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10
}

resource "aws_pipes_pipe" "sqs_to_sfn_cleanup" {
  name     = "sqs-to-sfn-cleanup-pipe"
  role_arn = aws_iam_role.lambda_roles["cleanup_task"].arn

  source = aws_sqs_queue.task_deletion_queue.arn
  target = aws_sfn_state_machine.task_cleanup_sfn.arn

  target_parameters {
    step_function_state_machine_parameters {
      invocation_type = "FIRE_AND_FORGET"
    }
  }
}

resource "aws_pipes_pipe" "sqs_to_sfn" {
  name     = "sqs-to-sfn-pipe"
  role_arn = aws_iam_role.lambda_roles["resizer"].arn

  source   = aws_sqs_queue.image_processing_queue.arn
  target   = aws_sfn_state_machine.image_processor_sfn.arn

  target_parameters {
    step_function_state_machine_parameters {
      invocation_type = "FIRE_AND_FORGET"
    }
  }
}

resource "aws_sqs_queue_policy" "allow_eventbridge" {
  queue_url = aws_sqs_queue.image_processing_queue.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = {
        Service = "events.amazonaws.com"
      }
      Action    = "sqs:SendMessage"
      Resource  = aws_sqs_queue.image_processing_queue.arn
      Condition = {
        ArnEquals = { "aws:SourceArn" = aws_cloudwatch_event_rule.s3_upload_rule.arn }
      }
    }]
  })
}
