locals {
  services = {
    for pair in setproduct(local.environments, var.application.services) :
    "${pair[0]}-${pair[1]}" => {
      env = pair[0]
      svc = pair[1]
    }
  }
}

resource "aws_service_discovery_service" "service" {
  for_each = local.services

  name = "${var.application.name}-${each.value.env}-${each.value.svc}"

  dns_config {
    namespace_id = var.cloudmap_namespace

    # When queried, return only one record at a time (as opposed to MULTIVALUE,
    # which returns all records at once)
    routing_policy = "WEIGHTED"

    # Support both A and AAAA records with a 10s TTL
    dns_records {
      type = "A"
      ttl  = 10
    }

    dns_records {
      type = "AAAA"
      ttl  = 10
    }
  }

  # Have ECS deregister instances as soon as one health check fails
  health_check_custom_config {
    failure_threshold = 1
  }

  tags = var.tags
}

# Create an SSM parameter for the Cloud Map service ARN
resource "aws_ssm_parameter" "service" {
  for_each = local.services

  name  = "${local.directory_prefix}/${each.value.env}/services/${each.value.svc}"
  type  = "String"
  value = aws_service_discovery_service.service[each.key].arn

  tags = var.tags
}
