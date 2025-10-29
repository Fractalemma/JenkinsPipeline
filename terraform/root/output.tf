output "project-url" {
  value = "http://${var.sub_domain}.${var.hosted_zone_name}"
}

output "jenkins-server" {
  value = "http://${module.jenkins-ec2.public_ip}"
}