locals {
  acm_subdomains = [
    for site in var.applications :
    site.name
    if site.acmSubdomain
  ]
}

module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 5.0"

  domain_name = "${var.name}.${var.dns.suffix}"

  subject_alternative_names = concat(
    ["*.${var.name}.${var.dns.suffix}"],
    formatlist("*.%s.%s.%s", local.acm_subdomains, var.name, var.dns.suffix)
  )

  wait_for_validation = true
  zone_id             = aws_route53_zone.public.id
  validation_method   = "DNS"
  tags = merge(var.tags, {
    Name = "${var.name}.${var.dns.suffix}"
  })
}
