resource "aws_dynamodb_table" "cloudstack_table" {
  name           = "CloudStackTable"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "userId"
  range_key      = "taskId"

  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "taskId"
    type = "S"
  }

  tags = {
    Name        = "CloudStackTable"
    Project     = "CloudStack"
    Environment = "Dev"
  }
}
