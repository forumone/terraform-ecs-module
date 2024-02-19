data "aws_iam_policy_document" "cron_eventbridge_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cron_eventbridge" {
  name = "${var.name}-CronEventBridge"

  assume_role_policy = data.aws_iam_policy_document.cron_eventbridge_assume.json
}

data "aws_iam_policy_document" "cron_ecs_run_task" {
  version = "2012-10-17"

  statement {
    sid       = "runTask"
    effect    = "Allow"
    actions   = ["ecs:RunTask"]
    resources = ["*"]

    condition {
      test     = "ArnEquals"
      variable = "ecs:cluster"
      values   = [module.ecs.cluster_arn]
    }
  }
}

resource "aws_iam_policy" "cron_ecs_run_task" {
  name   = "${var.name}-CronRunTask"
  policy = data.aws_iam_policy_document.cron_ecs_run_task.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "cron_ecs_run_task" {
  role       = aws_iam_role.cron_eventbridge.name
  policy_arn = aws_iam_policy.cron_ecs_run_task.arn
}

resource "aws_iam_role_policy_attachment" "cron_ecs_pass_role" {
  role       = aws_iam_role.cron_eventbridge.name
  policy_arn = aws_iam_policy.ecs_pass_role.arn
}

resource "aws_ssm_parameter" "cron_ecs_role" {
  name  = "/${var.name}/iam/eventbridge-cron"
  type  = "String"
  value = aws_iam_role.cron_eventbridge.arn
}
