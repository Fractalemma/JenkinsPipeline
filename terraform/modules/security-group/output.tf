output "alb_sg_id" {
  value = aws_security_group.alb_sg.id
}

output "web_sg_id" {
  value = aws_security_group.web_sg.id
}

output "pipeline_agent_sg_id" {
  value = aws_security_group.pipeline_agent_sg.id
}
