output "region" {
  value = var.region
}
output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "pub_sub_a_id" {
  value = aws_subnet.pub_sub_a.id
}
output "pub_sub_b_id" {
  value = aws_subnet.pub_sub_b.id
}

output "jenkins_sub_a_id" {
  value = aws_subnet.jenkins_sub_a.id
}
