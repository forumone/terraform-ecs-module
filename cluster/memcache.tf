resource "aws_elasticache_cluster" "memcache" {
  count = var.memcache == null ? 0 : 1

  cluster_id = "${var.name}-memcache"

  engine          = "memcached"
  engine_version  = var.memcache.engine_version
  node_type       = var.memcache.node_type
  num_cache_nodes = var.memcache.num_cache_nodes

  az_mode              = var.memcache.num_cache_nodes == 1 ? "single-az" : "cross-az"
  parameter_group_name = var.memcache.parameter_group_name
  subnet_group_name    = module.vpc.elasticache_subnet_group_name
  security_group_ids   = [aws_security_group.memcache[0].id]

  port = 11211

  tags = {
    Name = "${var.name}-memcache"
  }
}

# memcache default security group
resource "aws_security_group" "memcache" {
  count = var.memcache == null ? 0 : 1

  name   = "${var.name}-memcache"
  vpc_id = module.vpc.vpc_id
}

# Allow ingress from ECS
resource "aws_security_group_rule" "memcache_in" {
  count = var.memcache == null ? 0 : 1

  security_group_id        = aws_security_group.memcache[0].id
  type                     = "ingress"
  from_port                = 11211
  to_port                  = 11211
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs.id
}

# Allow egress to ECS
resource "aws_security_group_rule" "memcache_out" {
  count = var.memcache == null ? 0 : 1

  security_group_id        = aws_security_group.ecs.id
  type                     = "egress"
  from_port                = 11211
  to_port                  = 11211
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.memcache[0].id
}

resource "aws_ssm_parameter" "memcache_endpoint" {
  count = var.memcache == null ? 0 : 1

  name        = "/${var.name}/endpoints/memcache"
  description = "Configuration endpoint for memcache in the ${var.name} cluster"
  type        = "String"
  value       = aws_elasticache_cluster.memcache[0].configuration_endpoint

  tags = var.tags
}

resource "aws_ssm_parameter" "memcache_nodes_endpoint" {
  count = var.memcache == null ? 0 : 1

  name        = "/${var.name}/endpoints/memcache-nodes"
  description = "Endpoint list for all memcache nodes in the ${var.name} cluster"
  type        = "StringList"
  value       = join(",", [for node in aws_elasticache_cluster.memcache[0].cache_nodes : "${node.address}:${node.port}"])

  tags = var.tags
}
