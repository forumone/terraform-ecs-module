# GitHub Actions role: Lets the listed GitHub Actions workflows (through the
# account's GitHub OIDC provider) assume this cluster's builder and deployer
# roles, the same way Buildkite agents do. Only created when
# var.github_actions is set.

locals {
  # Subjects for the repository of each application with environments in this
  # cluster, plus any explicitly given subjects
  github_actions_subjects = var.github_actions == null ? [] : distinct(concat(
    var.github_actions.subjects,
    flatten([
      for app in var.applications : [
        for trigger in var.github_actions.triggers : "repo:${app.repository}:${trigger}"
      ] if app.repository != null && contains(keys(app.environments), var.name)
    ])
  ))

  # Added to the builder and deployer roles' trust policies
  github_actions_principals = aws_iam_role.github_actions[*].arn
}

data "aws_iam_policy_document" "github_actions_assume" {
  count   = var.github_actions == null ? 0 : 1
  version = "2012-10-17"

  statement {
    sid     = "GitHubActions"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.github_actions.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # StringEquals, not StringLike: every subject is matched exactly
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = local.github_actions_subjects
    }
  }
}

resource "aws_iam_role" "github_actions" {
  count = var.github_actions == null ? 0 : 1

  lifecycle {
    precondition {
      condition     = length(local.github_actions_subjects) > 0
      error_message = "github_actions allows no workflows: set triggers (with a repository on an application in this cluster) or subjects."
    }
  }

  name               = "${var.name}-GitHubActionsRole"
  description        = "GitHub Actions workflows building and deploying to the ${var.name} cluster"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume[0].json

  tags = local.tags
}

data "aws_iam_policy_document" "github_actions" {
  count   = var.github_actions == null ? 0 : 1
  version = "2012-10-17"

  statement {
    sid       = "assumeClusterRoles"
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = [aws_iam_role.buildkite_builder.arn, aws_iam_role.buildkite_deployer.arn]
  }
}

resource "aws_iam_role_policy" "github_actions" {
  count = var.github_actions == null ? 0 : 1

  name   = "AssumeClusterRoles"
  role   = aws_iam_role.github_actions[0].id
  policy = data.aws_iam_policy_document.github_actions[0].json
}
