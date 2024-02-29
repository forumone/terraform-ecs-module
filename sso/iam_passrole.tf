data "aws_iam_policy_document" "ecs_pass_role" {
  version = "2012-10-17"

  statement {
    sid     = "passRole"
    effect  = "Allow"
    actions = ["iam:PassRole"]

    resources = var.task_role_arns
  }
}

resource "aws_iam_policy" "ecs_pass_role" {
  name_prefix = "SSO-pass-role-"

  policy = data.aws_iam_policy_document.ecs_pass_role.json
}
