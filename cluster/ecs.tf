resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/${var.name}/ecs/exec"
  retention_in_days = var.logs.retention
}

module "ecs" {
  source       = "terraform-aws-modules/ecs/aws"
  version      = "~> 5.7"
  cluster_name = var.name

  cluster_configuration = {
    execute_command_configuration = {
      logging = "OVERRIDE"

      log_configuration = {
        cloud_watch_log_group_name = aws_cloudwatch_log_group.ecs.name
      }
    }
  }

  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 1
      }
    }
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = 1
      }
    }
  }

  # enable for debugging
  cluster_settings = {
    name  = "containerInsights",
    value = "disabled"
  }

  tags = var.tags
}

resource "aws_ssm_parameter" "cluster_arn" {
  name  = "/${var.name}/arn"
  type  = "String"
  value = module.ecs.cluster_arn

  tags = var.tags
}

# Generic assume role policy for ECS tasks
data "aws_iam_policy_document" "ecs_task_assume" {
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
