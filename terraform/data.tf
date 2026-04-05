data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_vpc_endpoint_service" "s3" {
  service      = "s3"
  service_type = "Gateway"
}

data "aws_vpc_endpoint_service" "dynamodb" {
  service      = "dynamodb"
  service_type = "Gateway"
}

data "aws_vpc_endpoint_service" "kms" {
  service      = "kms"
  service_type = "Interface"
}

data "aws_vpc_endpoint_service" "sts" {
  service      = "sts"
  service_type = "Interface"
}

data "aws_vpc_endpoint_service" "sqs" {
  service      = "sqs"
  service_type = "Interface"
}

data "aws_vpc_endpoint_service" "sns" {
  service      = "sns"
  service_type = "Interface"
}

data "aws_vpc_endpoint_service" "ssm" {
  service      = "ssm"
  service_type = "Interface"
}

data "aws_vpc_endpoint_service" "secretsmanager" {
  service      = "secretsmanager"
  service_type = "Interface"
}

data "aws_vpc_endpoint_service" "logs" {
  service      = "logs"
  service_type = "Interface"
}
