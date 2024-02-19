data "aws_region" "current" {}

resource "aws_cloudwatch_log_group" "traefik" {
  name = "/${var.ecs_cluster_name}/services/traefik"

  retention_in_days = var.cloudwatch_log_retention
}
