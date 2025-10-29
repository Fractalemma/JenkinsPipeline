variable "module_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket for artifacts"
  type        = string
}

variable "app_ec2_tag_key" {
  description = "Tag key to identify App EC2 instances for SSM commands"
  type        = string
  default     = "Role"
}

variable "app_ec2_tag_value" {
  description = "Tag value to identify App EC2 instances for SSM commands"
  type        = string
  default     = "App"
}
