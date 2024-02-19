# Create a private DNS namespace. Services will be a subdomain of the private
# DNS zone "apps.${var.name}.internal".
resource "aws_service_discovery_private_dns_namespace" "private_dns" {
  count = var.dns.cloudmap ? 1 : 0

  vpc = module.vpc.vpc_id

  name        = "apps.internal"
  description = "Private service discovery namespace for the ${var.name} cluster"

  tags = var.tags
}
