resource "aws_elasticache_replication_group" "redis" {
  count = var.redis == null ? 0 : 1

  replication_group_id       = "${var.name}-redis"
  description                = "${var.name}-redis"
  num_cache_clusters         = var.redis.num_cache_clusters
  node_type                  = var.redis.node_type
  automatic_failover_enabled = true
  multi_az_enabled           = true
  auto_minor_version_upgrade = true
  engine                     = "redis"
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  engine_version             = var.redis.engine_version
  parameter_group_name       = var.redis.parameter_group
  port                       = 6379
  subnet_group_name          = module.vpc.elasticache_subnet_group_name
  security_group_ids         = [aws_security_group.redis[0].id]
}

# redis default Security Group
resource "aws_security_group" "redis" {
  count = var.redis == null ? 0 : 1

  name = "${var.name}-redis"

  vpc_id = module.vpc.vpc_id

  tags = {
    Name = "${var.name}-redis"
  }
}

# Allow ingress from ECS
resource "aws_security_group_rule" "redis_in" {
  count = var.redis == null ? 0 : 1

  security_group_id        = aws_security_group.redis[0].id
  type                     = "ingress"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs.id
}

# Allow egress from ECS
resource "aws_security_group_rule" "redis_out" {
  count = var.redis == null ? 0 : 1

  security_group_id        = aws_security_group.ecs.id
  type                     = "egress"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.redis[0].id
}

resource "aws_ssm_parameter" "redis" {
  count = var.redis == null ? 0 : 1

  name        = "/${var.name}/endpoints/redis"
  description = "Redis primary endpoint address"
  type        = "String"
  value       = aws_elasticache_replication_group.redis[0].primary_endpoint_address
}
