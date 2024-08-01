resource "aws_security_group" "automation_ec2" {
  name        = "${var.name}-automation-ec2"
  description = "Security group for automation EC2 instances"
  vpc_id      = module.vpc.vpc_id

  tags = merge(local.tags, {
    Name = "${var.name}-automation-ec2"
  })
}

# HTTP outbound is allowed primarily because some RPM-based package managers
# only use HTTP (package integrity is verified after download by PGP
# signatures).
resource "aws_security_group_rule" "automation_ec2_http_out" {
  description = "Allows arbitrary HTTP outbound for EC2 instances"

  security_group_id = aws_security_group.automation_ec2.id

  type      = "egress"
  from_port = 80
  to_port   = 80
  protocol  = "tcp"

  cidr_blocks      = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
}

resource "aws_security_group_rule" "automation_ec2_https_out" {
  description = "Allows arbitrary HTTPS outbound for EC2 instances"

  security_group_id = aws_security_group.automation_ec2.id

  type      = "egress"
  from_port = 443
  to_port   = 443
  protocol  = "tcp"

  cidr_blocks      = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
}

# Allow networking to and from MySQL if that database cluster exists
resource "aws_security_group_rule" "automation_ec2_mysql_in" {
  count = var.mysql == null ? 0 : 1

  description              = "Ingress from EC2 instances to MySQL"
  security_group_id        = module.mysql[0].security_group_id
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.automation_ec2.id
}

resource "aws_security_group_rule" "automation_ec2_mysql_out" {
  count = var.mysql == null ? 0 : 1

  description              = "Egress from EC2 instances to MySQL"
  security_group_id        = aws_security_group.automation_ec2.id
  type                     = "egress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = module.mysql[0].security_group_id
}

# Ditto Postgres
resource "aws_security_group_rule" "automation_ec2_postgresql_in" {
  count = var.postgresql == null ? 0 : 1

  description              = "Ingress from ECS to PostgreSQL"
  security_group_id        = module.postgresql[0].security_group_id
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.automation_ec2.id
}

resource "aws_security_group_rule" "automation_ec2_postgresql_out" {
  count = var.postgresql == null ? 0 : 1

  description              = "Egress from ECS to PostgreSQL"
  security_group_id        = aws_security_group.automation_ec2.id
  type                     = "egress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = module.postgresql[0].security_group_id
}

resource "aws_security_group_rule" "automation_ec2_efs_out" {
  description = "Egress from automated EC2 instances to EFS"

  security_group_id        = aws_security_group.automation_ec2.id
  type                     = "egress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.efs.id
}

resource "aws_security_group_rule" "efs_automation_ec2_in" {
  description = "Ingress from automated EC2 instances to EFS"

  security_group_id        = aws_security_group.efs.id
  type                     = "ingress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.automation_ec2.id
}
