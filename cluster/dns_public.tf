data "aws_route53_zone" "public" {
  name = var.dns.suffix

  # Uses the AWS infrastructure account where DNS is hosted
  provider = aws.infrastructure
}

resource "aws_route53_zone" "public" {
  name = "${var.name}.${var.dns.suffix}"

  comment = "Delegated from Infrastructure AWS account - Managed by Terraform"
}

resource "aws_route53_record" "public_ns" {
  zone_id = data.aws_route53_zone.public.zone_id
  name    = aws_route53_zone.public.name
  type    = "NS"
  ttl     = 30
  records = aws_route53_zone.public.name_servers

  # Uses the AWS infrastructure account where DNS is hosted
  provider = aws.infrastructure
}

locals {
  dns_wildcard_name = var.dns.wildcard_target == "alb" ? aws_lb.alb.dns_name : aws_lb.nlb.dns_name
  dns_wildcard_zone = var.dns.wildcard_target == "alb" ? aws_lb.alb.zone_id : aws_lb.nlb.zone_id
}

resource "aws_route53_record" "nlb_ipv4" {
  zone_id = aws_route53_zone.public.zone_id
  name    = "*"
  type    = "A"

  alias {
    name                   = local.dns_wildcard_name
    zone_id                = local.dns_wildcard_zone
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "nlb_ipv6" {
  zone_id = aws_route53_zone.public.zone_id
  name    = "*"
  type    = "AAAA"

  alias {
    name                   = local.dns_wildcard_name
    zone_id                = local.dns_wildcard_zone
    evaluate_target_health = false
  }
}
