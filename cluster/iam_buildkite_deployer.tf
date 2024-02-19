# Buildkite deployer role: Reads SSM parameters, modifies ECS tasks, etc.

data "aws_iam_policy_document" "buildkite_deployer_assume" {
  version = "2012-10-17"

  statement {
    sid     = "1"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = var.buildkite.deployers
    }
  }
}

resource "aws_iam_role" "buildkite_deployer" {
  name               = "${var.name}-BuildkiteDeployerRole"
  assume_role_policy = data.aws_iam_policy_document.buildkite_deployer_assume.json

  tags = var.tags
}

# Policy: Manipulate ECS tasks, services, and auto scaling

data "aws_iam_policy_document" "buildkite_deploy_ecs" {
  version = "2012-10-17"

  statement {
    sid       = "readWriteServices"
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "ecs:CreateService",
      "ecs:DeleteService",
      "ecs:DescribeServices",
      "ecs:UpdateService",
    ]

    # Only allow modifying services on this cluster
    condition {
      test     = "StringEquals"
      variable = "ecs:cluster"
      values   = [module.ecs.cluster_arn, module.ecs.cluster_name]
    }
  }

  statement {
    sid    = "readWriteTaskDefinitions"
    effect = "Allow"

    actions = [
      "ecs:DescribeTaskDefinition",
      "ecs:RegisterTaskDefinition",
      "ecs:DeregisterTaskDefinition",
    ]

    # Task definition actions do not accept limiting by resource
    resources = ["*"]
  }

  # Per the AWS app auto scaling docs, these actions do not support limiting by resource
  statement {
    sid    = "readWriteAutoScaling"
    effect = "Allow"

    actions = [
      "application-autoscaling:RegisterScalableTarget",
      "application-autoscaling:DescribeScalableTargets",
      "application-autoscaling:DeregisterScalableTarget",
      "application-autoscaling:PutScalingPolicy",
      "application-autoscaling:DeleteScalingPolicy",
      "application-autoscaling:DescribeScalingPolicies",
      "application-autoscaling:ListTagsForResource"
    ]

    resources = ["*"]
  }

  # Permissions required for run-task helper to watch tasks
  statement {
    sid    = "commands"
    effect = "Allow"

    actions = [
      "ecs:DescribeTasks",
      "ecs:RunTask"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "ecs:cluster"
      values   = [module.ecs.cluster_arn, module.ecs.cluster_name]
    }
  }
}

resource "aws_iam_policy" "buildkite_deploy_ecs" {
  name        = "${var.name}-BuildkiteDeployerECSAccess"
  description = "Grants read/write access to ECS tasks, services, and autoscaling for the ${var.name} cluster"
  policy      = data.aws_iam_policy_document.buildkite_deploy_ecs.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "buildkite_deploy_ecs" {
  role       = aws_iam_role.buildkite_deployer.name
  policy_arn = aws_iam_policy.buildkite_deploy_ecs.arn
}

data "aws_iam_policy_document" "buildkite_deploy_pass_cron_role" {
  # Extend the base PassRole permissions document to allow passing the EventBridge role
  source_policy_documents = [data.aws_iam_policy_document.ecs_pass_role.json]

  statement {
    sid       = "passEventBridgeRole"
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = [aws_iam_role.cron_eventbridge.arn]
  }
}

resource "aws_iam_policy" "buildkite_deploy_pass_cron_role" {
  name        = "${var.name}-BuildkiteDeployerPassRole"
  policy      = data.aws_iam_policy_document.buildkite_deploy_pass_cron_role.json
  description = "Grants permission for Buildkite deployments to pass necessary ECS-related roles"

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "buildkite_deploy_pass_cron_role" {
  role       = aws_iam_role.buildkite_deployer.name
  policy_arn = aws_iam_policy.buildkite_deploy_pass_cron_role.arn
}

data "aws_iam_policy_document" "buildkite_deployer_terraform" {
  version = "2012-10-17"

  statement {
    sid       = "listStateBuckets"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [module.s3_tfstate.s3_bucket_arn]
  }

  statement {
    sid       = "readWriteStateObjects"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${module.s3_tfstate.s3_bucket_arn}/*"]
  }

  statement {
    sid       = "readWriteLocks"
    actions   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem"]
    resources = [aws_dynamodb_table.terraform_locks.arn]
  }

  statement {
    sid       = "readClusterParams"
    effect    = "Allow"
    actions   = ["ssm:GetParameter", "ssm:GetParameters"]
    resources = ["arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${var.name}/*"]
  }
}

resource "aws_iam_policy" "buildkite_deployer_terraform" {
  name        = "${var.name}-BuildkiteDeployerTerraform"
  description = "Grants permissions needed to perform Terraform deployments"
  policy      = data.aws_iam_policy_document.buildkite_deployer_terraform.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "buildkite_deployer_terraform" {
  role       = aws_iam_role.buildkite_deployer.name
  policy_arn = aws_iam_policy.buildkite_deployer_terraform.arn
}

data "aws_iam_policy_document" "buildkite_deployer_eventbridge" {
  version = "2012-10-17"

  statement {
    sid       = "manageRules"
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "events:DeleteRule",
      "events:DescribeRule",
      "events:ListTagsForResource",
      "events:PutRule",
    ]
  }

  statement {
    sid       = "manageTargets"
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "events:ListTargetsByRule",
      "events:PutTargets",
      "events:RemoveTargets",
    ]
  }
}

resource "aws_iam_policy" "buildkite_deployer_eventbridge" {
  name        = "${var.name}-BuildkiteDeployerEventBridge"
  policy      = data.aws_iam_policy_document.buildkite_deployer_eventbridge.json
  description = "Grants read/write access to EventBridge rules for Buildkite deployment jobs"

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "buildkite_deployer_eventbridge" {
  role       = aws_iam_role.buildkite_deployer.name
  policy_arn = aws_iam_policy.buildkite_deployer_eventbridge.arn
}
