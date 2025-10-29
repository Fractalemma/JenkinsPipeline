variable "module_prefix" {}
variable "instance_type" {
  default = "t3.micro"
}
variable "ami_id" {}
variable "user_data" {}
variable "iam_instance_profile" {}
variable "sg_id" {}
variable "max_size" {
  default = 4
}
variable "min_size" {
  default = 2
}
variable "desired_cap" {
  default = 2
}
variable "asg_health_check_grace_period" {
  default = 300
}
variable "asg_health_check_type" {
  default = "ELB"
}
variable "sub_a_id" {}
variable "sub_b_id" {}
variable "tg_arn" {}

# Variables for instance tagging
variable "instance_role_tag_key" {
  description = "Tag key to identify the role of instances created by this ASG"
  type        = string
  default     = "Role"
}

variable "instance_role_tag_value" {
  description = "Tag value to identify the role of instances created by this ASG"
  type        = string
  default     = "App"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}
