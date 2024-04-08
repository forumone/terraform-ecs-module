data "aws_iam_policy_document" "ecs_access" {
  version = "2012-10-17"

  statement {
    sid    = "listResources"
    effect = "Allow"

    actions = [
      "ecs:ListClusters",
      "ecs:ListTaskDefinitions",
      "ecs:ListTaskDefinitionFamilies",
      "ecs:ListTasks",
      "ecs:ListServices",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "describeResources"
    effect = "Allow"

    actions = [
      "ecs:DescribeClusters",
      "ecs:DescribeServices",
      "ecs:DescribeTaskDefinition",
      "ecs:DescribeTasks",
      "cloudwatch:GetMetricData"
    ]

    resources = ["*"]
  }

  statement {
    sid       = "runTask"
    effect    = "Allow"
    actions   = ["ecs:RunTask"]
    resources = ["*"]

    condition {
      test     = "ArnEquals"
      variable = "ecs:cluster"
      values   = var.ecs_cluster_arns
    }
  }
}

resource "aws_iam_policy" "ecs_access" {
  name_prefix = "SSO-cluster-access-"

  policy = data.aws_iam_policy_document.ecs_access.json
}
