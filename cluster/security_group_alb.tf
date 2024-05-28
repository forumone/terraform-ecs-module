# Security group for the ALB.
resource "aws_security_group" "alb" {
  name        = "${var.name}-alb"
  description = "Security group for the ALB"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name = "${var.name}-alb"
  }
}

resource "aws_security_group_rule" "alb_http_in_all" {
  security_group_id = aws_security_group.alb.id
  description       = "Allows arbitrary HTTP inbound"

  type      = "ingress"
  from_port = 80
  to_port   = 80
  protocol  = "tcp"

  cidr_blocks      = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
}

resource "aws_security_group_rule" "alb_https_in_all" {
  security_group_id = aws_security_group.alb.id
  description       = "Allows arbitrary HTTPS inbound"

  type      = "ingress"
  from_port = 443
  to_port   = 443
  protocol  = "tcp"

  cidr_blocks      = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
}
