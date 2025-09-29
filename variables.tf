variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "us-east-1"
}

variable "bucket_name" {
  type        = string
  description = "S3 bucket name"
}

variable "force_destroy" {
  type        = bool
  description = "Allow destroy even if bucket isn't empty"
  default     = false
}
