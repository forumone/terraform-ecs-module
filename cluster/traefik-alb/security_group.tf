# Create Security groups
resource "aws_security_group" "traefik" {
  name        = "${var.ecs_cluster_name}-traefik-alb"
  description = "Security group for the Traefik reverse proxy"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.ecs_cluster_name}-traefik-alb"
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


resource "aws_security_group_rule" "alb_traefik_out_http" {
  security_group_id = var.alb_security_group_id
  description       = "Egress from the ALB to Traefik (port 80)"

  type      = "egress"
  from_port = 80
  to_port   = 80
  protocol  = "tcp"

  source_security_group_id = aws_security_group.traefik.id
}

resource "aws_security_group_rule" "alb_traefik_in_http" {
  security_group_id = aws_security_group.traefik.id
  description       = "Ingress from the ALB to Traefik (port 80)"

  type      = "ingress"
  from_port = 80
  to_port   = 80
  protocol  = "tcp"

  source_security_group_id = var.alb_security_group_id
}

resource "aws_security_group_rule" "alb_traefik_out_ping" {
  security_group_id = var.alb_security_group_id
  description       = "Egress from the ALB to Traefik (port 8080)"

  type      = "egress"
  from_port = 80
  to_port   = 80
  protocol  = "tcp"

  source_security_group_id = aws_security_group.traefik.id
}

resource "aws_security_group_rule" "alb_traefik_in_piong" {
  security_group_id = aws_security_group.traefik.id
  description       = "Ingress from the ALB to Traefik (port 8080)"

  type      = "ingress"
  from_port = 80
  to_port   = 80
  protocol  = "tcp"

  source_security_group_id = var.alb_security_group_id
}
