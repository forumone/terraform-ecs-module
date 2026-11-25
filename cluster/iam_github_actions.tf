# GitHub Actions role: Lets the listed GitHub Actions workflows (through the
# account's GitHub OIDC provider) build, push, and deploy to this cluster using
# the same permissions as the Buildkite builder and deployer roles, which they
# do not assume. Only created when var.github_actions is set.

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

  # Workflows choose their own session length (role-duration-seconds), up to
  # this; the default of one hour is too short for long image builds and deploys
  max_session_duration = 43200

  tags = local.tags
}

data "aws_iam_policy_document" "github_actions" {
  count   = var.github_actions == null ? 0 : 1
  version = "2012-10-17"

  # Logging in to ECR Public (e.g. to pull public base images without being
  # rate limited) happens with this role's own credentials. Neither action
  # supports resource-level permissions.
  statement {
    sid    = "ecrPublicLogin"
    effect = "Allow"
    actions = [
      "ecr-public:GetAuthorizationToken",
      "sts:GetServiceBearerToken",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "github_actions" {
  count = var.github_actions == null ? 0 : 1

  name   = "ECRPublicLogin"
  role   = aws_iam_role.github_actions[0].id
  policy = data.aws_iam_policy_document.github_actions[0].json
}

# Workflows build, push, and deploy with this role's own credentials, so it
# gets the same access as the Buildkite builder and deployer roles
resource "aws_iam_role_policy_attachment" "github_actions" {
  for_each = var.github_actions == null ? {} : {
    ecr_push             = aws_iam_policy.buildkite_ecr_push.arn
    deploy_ecs           = aws_iam_policy.buildkite_deploy_ecs.arn
    deploy_pass_roles    = aws_iam_policy.buildkite_deploy_pass_cron_role.arn
    deployer_terraform   = aws_iam_policy.buildkite_deployer_terraform.arn
    deployer_eventbridge = aws_iam_policy.buildkite_deployer_eventbridge.arn
    automation_access    = aws_iam_policy.automation_access.arn
  }

  role       = aws_iam_role.github_actions[0].name
  policy_arn = each.value
}
