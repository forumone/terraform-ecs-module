# Create Security groups
resource "aws_security_group" "traefik" {
  name        = "${var.ecs_cluster_name}-traefik"
  description = "Security group for the Traefik reverse proxy"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.ecs_cluster_name}-traefik"
  }
}

resource "aws_security_group_rule" "traefik_https_egress" {
  description       = "Allows outbound HTTPS (needed to pull Docker images)"
  security_group_id = aws_security_group.traefik.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
}

resource "aws_security_group_rule" "public_traefik_http_ingress" {
  description       = "Allows incoming HTTP traffic from public subnets"
  security_group_id = aws_security_group.traefik.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = var.http_port
  to_port           = var.http_port
  cidr_blocks       = var.public_subnets_ipv4
  ipv6_cidr_blocks  = var.public_subnets_ipv6
}

resource "aws_security_group_rule" "public_traefik_https_ingress" {
  description       = "Allows incoming HTTPS traffic from public subnets"
  security_group_id = aws_security_group.traefik.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = var.https_port
  to_port           = var.https_port
  cidr_blocks       = var.public_subnets_ipv4
  ipv6_cidr_blocks  = var.public_subnets_ipv6
}
