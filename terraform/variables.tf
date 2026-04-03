variable "region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "production" {
  description = "Whether this is a production environment"
  type        = bool
  default     = true
}