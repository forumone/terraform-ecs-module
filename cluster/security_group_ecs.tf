# Default Security Group
resource "aws_security_group" "ecs" {
  name        = "${var.name}-ecs-application"
  description = "Default group for ECS"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name = "${var.name}-ecs-application"
  }
}
resource "aws_security_group_rule" "ecs_default_http_out_all" {
  security_group_id = aws_security_group.ecs.id
  description       = "Default access for ECS to HTTP outbound"
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
}

resource "aws_security_group_rule" "ecs_default_https_out_all" {
  security_group_id = aws_security_group.ecs.id
  description       = "Default access for ECS to HTTPS outbound"
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
}

# SMTP Sendgrid Outbound from all
resource "aws_security_group_rule" "ecs_default_smtp_out" {
  security_group_id = aws_security_group.ecs.id
  description       = "Default access for ECS to SMTP (Sendgrid)"
  type              = "egress"
  from_port         = 587
  to_port           = 587
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
}

# Allow Traefik to communicate with tasks on port 80
resource "aws_security_group_rule" "ecs_default_traefik_in_80" {
  description              = "Ingress from Traefik to ECS (port 80)"
  security_group_id        = aws_security_group.ecs.id
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = module.traefik.security_group_id
}

resource "aws_security_group_rule" "ecs_default_traefik_out_80" {
  description              = "Egress from Traefik to ECS (port 80)"
  security_group_id        = module.traefik.security_group_id
  type                     = "egress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs.id
}

# Allow Traefik to communicate with tasks on additional ports
resource "aws_security_group_rule" "ecs_default_traefik_in_extra" {
  # We can't toset() a list of numbers, so use zipmap() to force Terraform to
  # create a keyed map of ports (e.g., {"3000" = 3000}) so that we can for_each
  # over it.
  for_each = zipmap(var.networking.ingress_ports, var.networking.ingress_ports)

  description = "Ingress from Traefik to ECS (port ${each.key})"

  security_group_id        = aws_security_group.ecs.id
  type                     = "ingress"
  from_port                = each.value
  to_port                  = each.value
  protocol                 = "tcp"
  source_security_group_id = module.traefik.security_group_id
}

resource "aws_security_group_rule" "ecs_default_traefik_out_extra" {
  for_each = zipmap(var.networking.ingress_ports, var.networking.ingress_ports)

  description = "Egress from Traefik to ECS (port ${each.key})"

  security_group_id        = module.traefik.security_group_id
  type                     = "egress"
  from_port                = each.value
  to_port                  = each.value
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs.id
}

# Internal VPC MySQL access (only created if MySQL cluster is requested)
resource "aws_security_group_rule" "ecs_default_mysql_in" {
  count = var.mysql == null ? 0 : 1

  description              = "Ingress from ECS to MySQL"
  security_group_id        = module.mysql[0].security_group_id
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs.id
}

resource "aws_security_group_rule" "ecs_default_mysql_out" {
  count = var.mysql == null ? 0 : 1

  description              = "Egress from ECS to MySQL"
  security_group_id        = aws_security_group.ecs.id
  type                     = "egress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = module.mysql[0].security_group_id
}

# Internal VPC PostgreSQL access (only created if PostgreSQL cluster is requested)
resource "aws_security_group_rule" "ecs_default_postgresql_in" {
  count = var.postgresql == null ? 0 : 1

  description              = "Ingress from ECS to PostgreSQL"
  security_group_id        = module.postgresql[0].security_group_id
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs.id
}

resource "aws_security_group_rule" "ecs_default_postgresql_out" {
  count = var.postgresql == null ? 0 : 1

  description              = "Egress from ECS to PostgreSQL"
  security_group_id        = aws_security_group.ecs.id
  type                     = "egress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = module.postgresql[0].security_group_id
}

resource "aws_ssm_parameter" "ecs_default_security_group_id" {
  name  = "/${var.name}/security-groups/default"
  type  = "String"
  value = aws_security_group.ecs.id
}
