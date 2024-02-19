# Create IAM Roles and Policies
data "aws_iam_policy_document" "ecs_assume" {
  version = "2012-10-17"

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# Empty execution role; Traefik does not have any need for runtime setup beyond the default
resource "aws_iam_role" "traefik_exec" {
  name               = "${var.ecs_cluster_name}-TraefikExecution"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}

resource "aws_iam_role_policy_attachment" "traefik_exec" {
  role       = aws_iam_role.traefik_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Task role with access to ECS resources
resource "aws_iam_role" "traefik_task" {
  name               = "${var.ecs_cluster_name}-TraefikTask"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}

data "aws_iam_policy_document" "traefik_policy" {
  statement {
    sid    = "serviceDiscovery"
    effect = "Allow"

    actions = [
      "ecs:ListClusters",
      "ecs:DescribeClusters",
      "ecs:ListTasks",
      "ecs:DescribeTasks",
      "ecs:DescribeContainerInstances",
      "ecs:DescribeTaskDefinition",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "configurationDiscovery"
    effect = "Allow"

    actions   = ["s3:GetObject"]
    resources = ["${module.s3_traefik.s3_bucket_arn}/configuration.yaml"]
  }
}

resource "aws_iam_policy" "traefik_policy" {
  name   = "${var.ecs_cluster_name}-TraefikECSAccess"
  policy = data.aws_iam_policy_document.traefik_policy.json
}

resource "aws_iam_role_policy_attachment" "traefik_policy" {
  role       = aws_iam_role.traefik_task.name
  policy_arn = aws_iam_policy.traefik_policy.arn
}
