locals {
  log_group_pairs = setproduct(
    local.environments,
    concat(var.application.containers, var.application.logGroups)
  )

  # Create a map of log group names, organized by environment and log group
  log_groups = {
    for pair in local.log_group_pairs :
    "${pair[0]}-${pair[1]}" => {
      env   = pair[0]
      group = pair[1]
    }
  }
}

resource "aws_cloudwatch_log_group" "logs" {
  for_each = local.log_groups

  name = "${local.directory_prefix}/${each.value.env}/${each.value.group}"

  retention_in_days = var.cloudwatch_retention

  tags = var.tags
}
