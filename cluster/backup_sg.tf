resource "aws_security_group" "backups" {
  name        = "${var.name}-backups"
  description = "Supplementary security group for backups"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name = "${var.name}-backups"
  }
}

resource "aws_security_group_rule" "backups_ssh_out" {
  security_group_id = aws_security_group.backups.id
  description       = "Allows outbound SSH for rsync"

  type             = "egress"
  from_port        = 22
  to_port          = 22
  protocol         = "tcp"
  cidr_blocks      = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
}
