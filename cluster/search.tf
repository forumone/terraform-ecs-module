locals {
  # Map nice names to the AWS API's names for each of the logs
  search_name_map = {
    INDEX_SLOW_LOGS     = "index-slow-log"
    SEARCH_SLOW_LOGS    = "search-slow-log"
    ES_APPLICATION_LOGS = "application-logs"
  }
}

resource "aws_cloudwatch_log_group" "opensearch" {
  for_each = local.search_name_map

  name              = "/${var.name}/search/${each.value}"
  retention_in_days = var.logs.retention

  tags = var.tags
}

data "aws_iam_policy_document" "opensearch_log_publish" {
  statement {
    sid       = "1"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents", "logs:PutLogEventsBatch"]
    resources = flatten([for _, group in aws_cloudwatch_log_group.opensearch : [group.arn, "${group.arn}:log-stream:*"]])

    principals {
      type        = "Service"
      identifiers = ["es.amazonaws.com"]
    }
  }
}

resource "aws_cloudwatch_log_resource_policy" "opensearch_log_publish" {
  policy_name     = "${var.name}-OpenSearchPublishingAccess"
  policy_document = data.aws_iam_policy_document.opensearch_log_publish.json
}

resource "aws_security_group" "opensearch" {
  count = var.search == null ? 0 : 1

  name   = "${var.name}-opensearch"
  vpc_id = module.vpc.vpc_id

  description = "Security group for Elasticsearch/OpenSearch domains"

  tags = var.tags
}

resource "aws_security_group_rule" "opensearch_in" {
  count = var.search == null ? 0 : 1

  description              = "Ingress from ECS to OpenSearch"
  security_group_id        = aws_security_group.opensearch[0].id
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs.id
}

resource "aws_security_group_rule" "opensearch_out" {
  count = var.search == null ? 0 : 1

  description              = "Egress from ECS to OpenSearch"
  security_group_id        = aws_security_group.ecs.id
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.opensearch[0].id
}

resource "aws_opensearch_domain" "opensearch" {
  count = var.search == null ? 0 : 1

  domain_name    = "${var.name}-search"
  engine_version = var.search.engine_version

  cluster_config {
    dedicated_master_enabled = var.search.dedicated_node_count != 0
    dedicated_master_count   = var.search.dedicated_node_count
    dedicated_master_type    = var.search.dedicated_node_type

    instance_type  = var.search.instance_type
    instance_count = var.search.instance_count

    # Only enable zone awareness if we have multiple search nodes
    zone_awareness_enabled = var.search.instance_count > 1

    zone_awareness_config {
      # Our VPCs are almost always going to be 2 or 3 AZs, but go ahead and
      # truncate to 3 AZs if we build a 4-AZ VPC
      availability_zone_count = min(3, var.vpc.az_count)
    }
  }

  ebs_options {
    ebs_enabled = true
    volume_type = var.search.storage_type
    volume_size = var.search.storage_size

    # Additional options - needed if using the gp3 volume type
    iops       = var.search.storage_iops
    throughput = var.search.storage_throughput
  }

  # Enforce good security hygiene: Require HTTPS, at-rest encryption, and
  # encrypt links between OpenSearch nodes
  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  encrypt_at_rest {
    enabled = true
  }

  node_to_node_encryption {
    enabled = true
  }

  vpc_options {
    security_group_ids = [aws_security_group.opensearch[0].id]

    # Constrain the list of subnets in cases where zone awareness is disabled
    subnet_ids = var.search.instance_count > 1 ? module.vpc.database_subnets : [module.vpc.database_subnets[0]]
  }

  dynamic "log_publishing_options" {
    for_each = local.search_name_map
    iterator = options

    content {
      enabled                  = contains(var.search.enable_logs, options.key)
      log_type                 = options.key
      cloudwatch_log_group_arn = aws_cloudwatch_log_group.opensearch[options.key].arn
    }
  }

  tags = var.tags

  depends_on = [aws_cloudwatch_log_resource_policy.opensearch_log_publish]
}

resource "aws_ssm_parameter" "opensearch" {
  count = var.search == null ? 0 : 1

  name  = "/${var.name}/endpoints/search"
  type  = "String"
  value = aws_opensearch_domain.opensearch[0].endpoint

  tags = var.tags
}
