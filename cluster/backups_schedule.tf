data "aws_iam_policy_document" "events_backups_assume_role" {
  version = "2012-10-17"

  statement {
    sid     = "1"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "events_backups" {
  name               = "${var.name}-BackupsCron"
  assume_role_policy = data.aws_iam_policy_document.events_backups_assume_role.json

  tags = local.tags
}

data "aws_iam_policy_document" "events_backups_pass_role" {
  version = "2012-10-17"

  statement {
    sid       = "passBackupRoles"
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = [aws_iam_role.backups_exec.arn, aws_iam_role.backups_task.arn]
  }
}

resource "aws_iam_policy" "events_backups_pass_role" {
  name        = "${var.name}-BackupsPassRole"
  description = "Grants EventBridge permission to pass backup roles"

  policy = data.aws_iam_policy_document.events_backups_pass_role.json

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "events_backups_pass_role" {
  role       = aws_iam_role.events_backups.name
  policy_arn = aws_iam_policy.events_backups_pass_role.arn
}

data "aws_iam_policy_document" "events_backups_write_dead_letters" {
  version = "2012-10-17"

  statement {
    sid       = "writeDeadLetters"
    effect    = "Allow"
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.backups_dead_letters.arn]
  }
}

resource "aws_iam_policy" "events_backups_write_dead_letters" {
  name   = "${var.name}-BackupsWriteDeadLetters"
  policy = data.aws_iam_policy_document.events_backups_write_dead_letters.json

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "events_backups_write_dead_letters" {
  role       = aws_iam_role.events_backups.name
  policy_arn = aws_iam_policy.events_backups_write_dead_letters.arn
}

data "aws_iam_policy_document" "events_backups_ecs" {
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

  statement {
    sid       = "tagTask"
    effect    = "Allow"
    actions   = ["ecs:TagResource"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "ecs:CreateAction"
      values   = ["RunTask"]
    }
  }
}

resource "aws_iam_policy" "events_backups_ecs" {
  name   = "${var.name}-BackupsECS"
  policy = data.aws_iam_policy_document.events_backups_ecs.json

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "events_backups_ecs" {
  role       = aws_iam_role.events_backups.name
  policy_arn = aws_iam_policy.events_backups_ecs.arn
}
