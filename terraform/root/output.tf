output "project-url" {
  value = "http://${var.sub_domain}.${var.hosted_zone_name}"
}

output "alb-alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "jenkins-server" {
  value = "http://${module.jenkins-ec2.public_ip}:8080"
}

output "jenkins-webhook-endpoint" {
  value = "http://${module.jenkins-ec2.public_ip}:8080/github-webhook/"
}

output "s3-bucket-name" {
  value = var.bucket_name
}
