# Fetch the public Route 53 hosted zone
data "aws_route53_zone" "public-zone" {
  name         = var.hosted_zone_name
  private_zone = false
}

# R53 A record for the ALB
resource "aws_route53_record" "alb_record" {
  zone_id = data.aws_route53_zone.public-zone.zone_id
  name    = "${var.sub_domain}.${data.aws_route53_zone.public-zone.name}"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_hosted_zone_id
    evaluate_target_health = false
  }
}