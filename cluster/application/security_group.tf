locals {
  security_groups = {
    for pair in setproduct(local.environments, var.application.securityGroups) :
    "${pair[0]}-${pair[1]}" => {
      env = pair[0]
      sg  = pair[1]
    }
  }
}

resource "aws_security_group" "custom" {
  for_each = local.security_groups

  vpc_id = var.vpc_id
  name   = "${var.cluster_name}-${var.application.name}-${each.value.env}-${each.value.sg}"

  tags = merge(var.tags, {
    Name = "${var.cluster_name} ${var.application.name}: ${each.key}"
  })
}

resource "aws_ssm_parameter" "security_group" {
  for_each = local.security_groups

  name  = "${local.directory_prefix}/${each.value.env}/security-groups/${each.value.sg}"
  type  = "String"
  value = aws_security_group.custom[each.key].id

  tags = var.tags
}
