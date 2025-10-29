variable "module_prefix" {
  description = "The prefix for the resources."
  type        = string
}

variable "vpc_id" {
  description = "The VPC ID where the security group will be created."
  type        = string
}

variable "subnet_id" {
  description = "The Subnet ID where the instance will be launched."
  type        = string
}

variable "sg_id" {
  description = "The Security Group ID to associate with the instance."
  type        = string
}

variable "instance_type" {
  description = "The type of instance to use."
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "The AMI ID to use for the instance."
  type        = string
}

variable "user_data" {
  description = "The user data to provide when launching the instance."
  type        = string
  default     = ""
}

variable "iam_instance_profile" {
  type    = string
  default = null
}

variable "enable_public_ip" {
  description = "Whether to associate a public IP address with the instance."
  type        = bool
  default     = true
}
