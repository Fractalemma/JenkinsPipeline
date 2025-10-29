variable "region" {}
variable "aws_profile" {}
variable "project_name" {}

variable "bucket_name" {
  default = "jenkins-pipeline-emmanuel-engineering-com"
}

variable "vpc_cidr" {
  # 10.123.0.0 - 10.123.255.255 (65536 IPs)
  default = "10.0.0.0/16"
}

variable "pub_sub_a_cidr" {
  # 10.123.1.4 - 10.123.1.254 (251 IPs)
  default = "10.0.1.0/24"
}
variable "pub_sub_b_cidr" {
  # 10.123.2.4 - 10.123.2.254 (251 IPs)
  default = "10.0.2.0/24"
}

variable "pub_sub_jenkins_a_cidr" {
  # 10.123.3.4 - 10.123.3.254 (251 IPs)
  default = "10.0.3.0/24"
}


variable "jenkins_allowed_http_cidrs" {}


variable "sub_domain" {
  default = "jenkins-pipeline"
}
variable "hosted_zone_name" {
  default = "emmanuelengineering.com"
}
