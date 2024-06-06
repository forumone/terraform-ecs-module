# We create roles on a per-environment basis
locals {
  roles = {
    for pair in setproduct(local.environments, var.application.roles) :
    "${pair[0]}-${pair[1]}" => {
      env  = pair[0]
      role = pair[1]
    }
  }
}

data "aws_iam_policy_document" "ecs_tasks_assume" {
  version = "2012-10-17"

  statement {
    sid     = "1"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# Since these are task roles (not execution roles), we don't have any canned policies to attach to this
resource "aws_iam_role" "custom" {
  for_each = local.roles

  name        = "${var.cluster_name}-${var.application.name}-${each.value.env}-${each.value.role}-TaskRole"
  description = "Custom task role for ${var.application.name}'s ${each.value.role} role in ${each.value.env}"

  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume.json

  tags = var.tags
}

# Store role ARNs as SSM parameters for easier access by downstream deployments
resource "aws_ssm_parameter" "iam_role_arn" {
  for_each = local.roles

  name  = "${local.directory_prefix}/${each.value.env}/iam/${each.value.role}/arn"
  type  = "String"
  value = aws_iam_role.custom[each.key].arn

  tags = var.tags
}
