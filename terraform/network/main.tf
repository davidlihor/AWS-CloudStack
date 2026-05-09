terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 6.44"
      configuration_aliases = [aws.virginia]
    }
  }
}
