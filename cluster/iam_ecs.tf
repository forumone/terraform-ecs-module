# ECS Assume Role Policy
data "aws_iam_policy_document" "ecs_assume_role_policy" {
  version = "2012-10-17"

  statement {
    sid     = "1"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# Default task role for ECS
resource "aws_iam_role" "ecs_default_task" {
  name               = "${var.name}-DefaultTask"
  description        = "Default Execution Role for ECS Tasks"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role_policy.json

  tags = var.tags
}

# Grant non-root EFS access through access points in this VPC
data "aws_iam_policy_document" "efs_mount_access" {
  version = "2012-10-17"
  statement {
    sid       = "readWriteMount"
    effect    = "Allow"
    actions   = ["elasticfilesystem:ClientMount", "elasticfilesystem:ClientWrite"]
    resources = ["*"]

    # Only allow mounting through an access point: this check requires that the
    # efs:AccessPointArn attribute is present on EFS mount requests.
    condition {
      test     = "Null"
      values   = ["false"]
      variable = "elasticfilesystem:AccessPointArn"
    }
  }
}

resource "aws_iam_policy" "efs_mount_access" {
  name   = "${var.name}-Task-EFSAccess"
  policy = data.aws_iam_policy_document.efs_mount_access.json
}

resource "aws_iam_role_policy_attachment" "efs_mount_access" {
  role       = aws_iam_role.ecs_default_task.name
  policy_arn = aws_iam_policy.efs_mount_access.arn
}

# If a search cluster was deployed, grant IAM-based access to manage data
data "aws_iam_policy_document" "ecs_search_access" {
  count = var.search == null ? 0 : 1

  version = "2012-10-17"

  statement {
    sid    = "readWriteSearchData"
    effect = "Allow"

    # matches HTTP verbs (e.g., Delete, Get, Head, Patch, Post, Put)
    actions   = ["es:ESHttp*"]
    resources = ["${aws_opensearch_domain.opensearch[0].arn}/*"]
  }
}

resource "aws_iam_policy" "ecs_search_access" {
  count = var.search == null ? 0 : 1

  name        = "${var.name}-SearchAccess"
  description = "Grants permission to manage data in Elasticsearch/OpenSearch in the ${var.name} cluster"
  policy      = data.aws_iam_policy_document.ecs_search_access[0].json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ecs_search_access" {
  count = var.search == null ? 0 : 1

  role       = aws_iam_role.ecs_default_task.name
  policy_arn = aws_iam_policy.ecs_search_access[0].arn
}

# Execution role used to set up tasks
resource "aws_iam_role" "ecs_default_exec" {
  name               = "${var.name}-DefaultExecution"
  description        = "Default Task Role for ECS Tasks"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role_policy.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ecs_default_exec" {
  role       = aws_iam_role.ecs_default_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Grant access to non-internal secrets
data "aws_iam_policy_document" "secrets_manager_read_only" {
  version = "2012-10-17"
  statement {
    sid       = "getSecrets"
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = ["*"]

    # Don't allow reads of secrets that are flagged as internal
    condition {
      test     = "Null"
      values   = ["true"]
      variable = "aws:ResourceTag/f1-internal"
    }
  }
}

resource "aws_iam_policy" "secrets_manager_read_only" {
  name   = "${var.name}-Task-SecretsAccess"
  policy = data.aws_iam_policy_document.secrets_manager_read_only.json
}

resource "aws_iam_role_policy_attachment" "secrets_manager_read_only" {
  role       = aws_iam_role.ecs_default_exec.name
  policy_arn = aws_iam_policy.secrets_manager_read_only.arn
}

# Grant access to parameters scoped by this cluster name
data "aws_iam_policy_document" "parameter_store_read_only" {
  version = "2012-10-17"
  statement {
    sid       = "readParameters"
    effect    = "Allow"
    actions   = ["ssm:GetParameters", "ssm:GetParameter"]
    resources = ["arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${var.name}/*"]
  }
}

resource "aws_iam_policy" "parameter_store_read_only" {
  name   = "${var.name}-Task-ParameterAccess"
  policy = data.aws_iam_policy_document.parameter_store_read_only.json
}

resource "aws_iam_role_policy_attachment" "parameter_store_read_only" {
  role       = aws_iam_role.ecs_default_exec.name
  policy_arn = aws_iam_policy.parameter_store_read_only.arn
}

# Grant permission to read environment files in S3
data "aws_iam_policy_document" "env_read_only" {
  version = "2012-10-17"

  statement {
    sid       = "readFiles"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${module.s3_env.s3_bucket_arn}/*"]
  }
}

resource "aws_iam_policy" "env_read_only" {
  name   = "${var.name}-Task-S3EnvAcces"
  policy = data.aws_iam_policy_document.env_read_only.json
}

resource "aws_iam_role_policy_attachment" "env_read_only" {
  role       = aws_iam_role.ecs_default_exec.name
  policy_arn = aws_iam_policy.env_read_only.arn
}

resource "aws_ssm_parameter" "ecs_default_task" {
  name  = "/${var.name}/iam/ecs-task"
  type  = "String"
  value = aws_iam_role.ecs_default_task.arn
}

resource "aws_ssm_parameter" "ecs_default_exec" {
  name  = "/${var.name}/iam/ecs-exec"
  type  = "String"
  value = aws_iam_role.ecs_default_exec.arn
}

# Grant access for tasks to write to cloud watch and create streams
data "aws_iam_policy_document" "cloudwatch_access" {
  version = "2012-10-17"

  statement {
    sid    = "writeCloudWatchData"
    effect = "Allow"

    # matches HTTP verbs (e.g., Delete, Get, Head, Patch, Post, Put)
    actions = [
      "logs:PutLogEvents",
      "logs:CreateLogStream"
    ]
    resources = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/${var.name}/*"]
  }
}

resource "aws_iam_policy" "cloudwatch_access" {
  name   = "${var.name}-Task-cloudWatchAccess"
  policy = data.aws_iam_policy_document.cloudwatch_access.json
}

resource "aws_iam_role_policy_attachment" "cloudwatch_access" {
  role       = aws_iam_role.ecs_default_exec.name
  policy_arn = aws_iam_policy.cloudwatch_access.arn
}
