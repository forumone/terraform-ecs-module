resource "aws_security_group" "efs" {
  name        = "${var.name}-efs"
  description = "Default access for ECS to EFS"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name = "${var.name}-efs"
  }
}

resource "aws_security_group_rule" "ecs_default_efs_out" {
  description = "Egress from ECS to EFS"

  security_group_id        = aws_security_group.ecs.id
  type                     = "egress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.efs.id
}

resource "aws_security_group_rule" "efs_default_ecs_in" {
  description = "Ingress from ECS to EFS"

  security_group_id        = aws_security_group.efs.id
  type                     = "ingress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs.id
}
