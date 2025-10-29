output "alb_dns_name" {
  value = aws_lb.application_load_balancer.dns_name
}
output "alb_hosted_zone_id" {
  value = aws_lb.application_load_balancer.zone_id
}
output "alb_arn" {
  value = aws_lb.application_load_balancer.arn
}
output "tg_arn" {
  value = aws_lb_target_group.alb_target_group.arn
}