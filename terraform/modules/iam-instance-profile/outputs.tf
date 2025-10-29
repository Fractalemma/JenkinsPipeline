# Jenkins EC2 Role outputs
output "jenkins_ec2_role_arn" {
  description = "ARN of the Jenkins EC2 IAM role"
  value       = aws_iam_role.jenkins_ec2_role.arn
}

output "jenkins_ec2_role_name" {
  description = "Name of the Jenkins EC2 IAM role"
  value       = aws_iam_role.jenkins_ec2_role.name
}

output "jenkins_ec2_instance_profile_name" {
  description = "Name of the Jenkins EC2 instance profile"
  value       = aws_iam_instance_profile.jenkins_ec2_profile.name
}

output "jenkins_ec2_instance_profile_arn" {
  description = "ARN of the Jenkins EC2 instance profile"
  value       = aws_iam_instance_profile.jenkins_ec2_profile.arn
}

# App EC2 Role outputs
output "app_ec2_role_arn" {
  description = "ARN of the App EC2 IAM role"
  value       = aws_iam_role.app_ec2_role.arn
}

output "app_ec2_role_name" {
  description = "Name of the App EC2 IAM role"
  value       = aws_iam_role.app_ec2_role.name
}

output "app_ec2_instance_profile_name" {
  description = "Name of the App EC2 instance profile"
  value       = aws_iam_instance_profile.app_ec2_profile.name
}

output "app_ec2_instance_profile_arn" {
  description = "ARN of the App EC2 instance profile"
  value       = aws_iam_instance_profile.app_ec2_profile.arn
}