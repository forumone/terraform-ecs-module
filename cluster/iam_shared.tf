# Base PassRole permissions for anything interacting with the cluster
data "aws_iam_policy_document" "ecs_pass_role" {
  version = "2012-10-17"

  statement {
    sid     = "passRole"
    effect  = "Allow"
    actions = ["iam:PassRole"]

    resources = concat(
      # Default task and execution roles
      [aws_iam_role.ecs_default_exec.arn, aws_iam_role.ecs_default_task.arn],

      # Custom roles created for applications
      flatten([
        for _, application in module.application :
        values(application.iam_role_arns)
      ])
    )
  }
}

resource "aws_iam_policy" "ecs_pass_role" {
  name        = "${var.name}-ECSPassRole"
  description = "Grants permission to use the ECS IAM task roles for the ${var.name} cluster"
  policy      = data.aws_iam_policy_document.ecs_pass_role.json

  tags = var.tags
}
