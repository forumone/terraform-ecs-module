module "mysql" {
  count = var.mysql == null ? 0 : 1

  source  = "terraform-aws-modules/rds-aurora/aws"
  version = "~> 7.6"

  name           = "${var.name}-aurora-mysql"
  engine         = "aurora-mysql"
  engine_version = var.mysql.engine_version
  instance_class = var.mysql.instance_type

  create_db_parameter_group     = true
  db_parameter_group_family     = var.mysql.db_parameter_family
  db_parameter_group_parameters = var.mysql.db_parameters

  instances = {
    for i in range(var.mysql.replica_count) :
    i => {}
  }

  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.database_subnets

  storage_encrypted   = true
  apply_immediately   = true
  monitoring_interval = 5

  tags = var.tags
}

resource "aws_secretsmanager_secret" "mysql_root_credentials" {
  count = var.mysql == null ? 0 : 1

  name        = "/${var.name}/databases/mysql/root"
  description = "Root credentials for MySQL"

  recovery_window_in_days = 0

  tags = merge(var.tags, {
    "f1-internal" = "true"
  })
}

resource "aws_secretsmanager_secret_version" "mysql_root_credentials" {
  count = var.mysql == null ? 0 : 1

  secret_id = aws_secretsmanager_secret.mysql_root_credentials[0].id

  # cf. https://docs.aws.amazon.com/secretsmanager/latest/userguide/reference_secret_json_structure.html#reference_secret_json_structure_rds-mysql
  secret_string = jsonencode({
    engine   = "mysql"
    host     = module.mysql[0].cluster_endpoint
    port     = module.mysql[0].cluster_port
    username = module.mysql[0].cluster_master_username
    password = module.mysql[0].cluster_master_password
  })

  lifecycle {
    ignore_changes = [version_stages, secret_string]
  }
}

resource "aws_ssm_parameter" "mysql_endpoint" {
  count = var.mysql == null ? 0 : 1
  name  = "/${var.name}/endpoints/mysql-writer"
  type  = "String"
  value = module.mysql[0].cluster_endpoint
}

resource "aws_ssm_parameter" "mysql_ro_endpoint" {
  count = var.mysql == null ? 0 : 1
  name  = "/${var.name}/endpoints/mysql-reader"
  type  = "String"
  value = module.mysql[0].cluster_reader_endpoint
}
