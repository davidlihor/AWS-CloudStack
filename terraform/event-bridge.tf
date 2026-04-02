resource "aws_cloudwatch_event_rule" "s3_upload_rule" {
  name        = "capture-s3-photo-upload"
  description = "Send only photo.png to processing"

  event_pattern = jsonencode({
    "source": ["aws.s3"],
    "detail-type": ["Object Created"],
    "detail": {
      "bucket": { "name": ["${module.s3_data.s3_bucket_id}"] },
      "object": { "key": [{ "suffix": "photo.png" }] }
    }
  })
}

resource "aws_cloudwatch_event_target" "sqs_target" {
  rule      = aws_cloudwatch_event_rule.s3_upload_rule.name
  target_id = "SendToSQS"
  arn       = aws_sqs_queue.image_processing_queue.arn
}
