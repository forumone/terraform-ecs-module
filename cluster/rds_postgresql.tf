module "postgresql" {
  count = var.postgresql == null ? 0 : 1

  source  = "terraform-aws-modules/rds-aurora/aws"
  version = "~> 7.6"

  name           = "${var.name}-aurora-postgresql"
  engine         = "aurora-postgresql"
  engine_version = var.postgresql.engine_version
  instance_class = var.postgresql.instance_type

  instances = {
    for i in range(var.postgresql.replica_count) :
    i => {}
  }

  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.database_subnets

  storage_encrypted   = true
  apply_immediately   = true
  monitoring_interval = 5

  tags = var.tags
}

resource "aws_secretsmanager_secret" "postgresql_root_credentials" {
  count = var.postgresql == null ? 0 : 1

  name        = "/${var.name}/databases/postgresql/root"
  description = "Root credentials for PostgreSQL"

  recovery_window_in_days = 0

  tags = merge(var.tags, {
    "f1-internal" = "true"
  })
}

resource "aws_secretsmanager_secret_version" "postgresql_root_credentials" {
  count = var.postgresql == null ? 0 : 1

  secret_id = aws_secretsmanager_secret.postgresql_root_credentials[0].id

  # cf. https://docs.aws.amazon.com/secretsmanager/latest/userguide/reference_secret_json_structure.html#reference_secret_json_structure_rds-postgres
  secret_string = jsonencode({
    engine   = "postgres"
    host     = module.postgresql[0].cluster_endpoint
    port     = module.postgresql[0].cluster_port
    username = module.postgresql[0].cluster_master_username
    password = module.postgresql[0].cluster_master_password
  })

  lifecycle {
    ignore_changes = [version_stages, secret_string]
  }
}

resource "aws_ssm_parameter" "postgresql_endpoint" {
  count = var.postgresql == null ? 0 : 1
  name  = "/${var.name}/endpoints/postgresql-writer"
  type  = "String"
  value = module.postgresql[0].cluster_endpoint
}

resource "aws_ssm_parameter" "postgresql_ro_endpoint" {
  count = var.postgresql == null ? 0 : 1
  name  = "/${var.name}/endpoints/postgresql-reader"
  type  = "String"
  value = module.postgresql[0].cluster_reader_endpoint
}
