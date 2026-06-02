# Buildkite builder role: Builds and pushes Docker images to this cluster's ECR repositories

data "aws_iam_policy_document" "buildkite_builder_assume" {
  version = "2012-10-17"

  statement {
    sid     = "1"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = var.buildkite.builders
    }
  }
}

resource "aws_iam_role" "buildkite_builder" {
  name               = "${var.name}-BuildkiteBuilderRole"
  assume_role_policy = data.aws_iam_policy_document.buildkite_builder_assume.json

  tags = local.tags
}

data "aws_iam_policy_document" "buildkite_ecr_push" {
  version = "2012-10-17"

  statement {
    sid       = "login"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid    = "readWriteImages"
    effect = "Allow"

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:DescribeImages",
      "ecr:BatchGetImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage"
    ]

    resources = ["arn:aws:ecr:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:repository/${var.name}/*"]
  }
}

resource "aws_iam_policy" "buildkite_ecr_push" {
  name        = "${var.name}-BuildkiteBuilderECRAccess"
  description = "Grants read/write access to the ECR repositories for the ${var.name} cluster"
  policy      = data.aws_iam_policy_document.buildkite_ecr_push.json

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "buildkite_ecr_push" {
  role       = aws_iam_role.buildkite_builder.name
  policy_arn = aws_iam_policy.buildkite_ecr_push.arn
}


locals {
  buildkite_s3_policies = {
    for pair in flatten([
      for app_name, application in module.application : [
        for bucket_key, policy_arn in application.s3_bucket_policies : {
          key        = "${app_name}/${bucket_key}"
          policy_arn = policy_arn
        }
      ]
    ]) : pair.key => pair.policy_arn
  }
}

resource "aws_iam_role_policy_attachment" "buildkite_s3_access" {
  for_each = local.buildkite_s3_policies

  role       = aws_iam_role.buildkite_builder.name
  policy_arn = each.value
}