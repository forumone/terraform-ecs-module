# AWS Event Bridge
resource "aws_cloudwatch_event_rule" "db_creation" {
  count = local.db_create ? 1 : 0

  name                = "${var.name}-terraform-database-creation"
  description         = "${var.name} terraform database creation for ECS Fargate"
  schedule_expression = "rate(2 hours)"
}

resource "aws_cloudwatch_event_target" "mysql_db_creation" {
  count = var.mysql == null ? 0 : 1

  arn      = module.ecs.cluster_arn
  rule     = aws_cloudwatch_event_rule.db_creation[0].name
  role_arn = aws_iam_role.db_scheduled_event_bridge.arn

  ecs_target {
    launch_type = "FARGATE"

    task_count          = 1
    task_definition_arn = aws_ecs_task_definition.terraform_mysql_database_exec[0].arn

    network_configuration {
      subnets         = module.vpc.private_subnets
      security_groups = [aws_security_group.ecs.id]
    }
  }
}

resource "aws_cloudwatch_event_target" "postgresql_db_creation" {
  count = var.postgresql == null ? 0 : 1

  arn      = module.ecs.cluster_arn
  rule     = aws_cloudwatch_event_rule.db_creation[0].name
  role_arn = aws_iam_role.db_scheduled_event_bridge.arn

  ecs_target {
    launch_type = "FARGATE"

    task_count          = 1
    task_definition_arn = aws_ecs_task_definition.terraform_postgresql_database_exec[0].arn

    network_configuration {
      subnets         = module.vpc.private_subnets
      security_groups = [aws_security_group.ecs.id]
    }
  }
}
