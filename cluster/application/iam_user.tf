# Same as roles, we create users on a per-environment basis
locals {
  users = {
    for pair in setproduct(local.environments, var.application.users) :
    "${pair[0]}-${pair[1]}" => {
      env  = pair[0]
      user = pair[1]
    }
  }
}

# Network boundary assertion. This IAM policy, when directly attached to a user,
# prevents their credentials from being used outside the VPC in which they are
# intended.
data "aws_iam_policy_document" "network_boundary" {
  version = "2012-10-17"

  statement {
    sid       = "assertNetworkBoundary"
    effect    = "Deny"
    actions   = ["*"]
    resources = ["*"]

    condition {
      test     = "StringNotEquals"
      variable = "aws:SourceVpc"
      values   = [var.vpc_id]
    }
  }
}

resource "aws_iam_user" "custom" {
  for_each = local.users

  name = "${var.cluster_name}-${var.application.name}-${each.value.env}-${each.value.user}"

  tags = merge(local.tags, {
    "forumone:environment" = each.value.env
  })
}

# Attach the boundary policy
resource "aws_iam_user_policy" "network_boundary" {
  for_each = local.users

  user   = aws_iam_user.custom[each.key].name
  policy = data.aws_iam_policy_document.network_boundary.json
}

resource "aws_iam_access_key" "custom" {
  for_each = local.users

  user = aws_iam_user.custom[each.key].name
}

# Store generated credentials in Secrets Manager for runtime access by deployed
# containers.
resource "aws_secretsmanager_secret" "iam_credentials" {
  for_each = local.users

  name        = "${local.directory_prefix}/${each.value.env}/iam/${each.value.user}/keys"
  description = "IAM access keys for the ${each.value.env}/${each.value.user} user"

  tags = merge(local.tags, {
    "forumone:environment" = each.value.env
  })
}

resource "aws_secretsmanager_secret_version" "iam_credentials" {
  for_each = local.users

  secret_id = aws_secretsmanager_secret.iam_credentials[each.key].id

  secret_string = jsonencode(({
    access_key_id     = aws_iam_access_key.custom[each.key].id
    secret_access_key = aws_iam_access_key.custom[each.key].secret
  }))
}
