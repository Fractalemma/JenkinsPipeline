variable "module_prefix" {}
variable "vpc_id" {}
variable "jenkins_allowed_http_cidrs" {
  type = list(string)
}