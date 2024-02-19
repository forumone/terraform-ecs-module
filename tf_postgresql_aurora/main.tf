# Create Users List
locals {
  users = {
    for database in var.databases : "${database.name}-${database.env}-${database.db}" =>
    database
  }
}

resource "postgresql_database" "database" {
  for_each = local.users

  name       = each.key
  lc_collate = "en_US.UTF-8"
  encoding   = "utf8"
}

resource "random_password" "password" {
  for_each = local.users

  length = 20
}

resource "postgresql_role" "user" {
  for_each = local.users

  name     = postgresql_database.database[each.key].name
  login    = true
  password = random_password.password[each.key].result
}


resource "postgresql_grant" "database_privileges" {
  for_each = local.users

  database    = postgresql_database.database[each.key].name
  role        = postgresql_role.user[each.key].name
  object_type = "database"
  # If ALL does not work here we may need to specify each privilege see:
  # https://registry.terraform.io/providers/cyrilgdn/postgresql/latest/docs/resources/postgresql_grant#privileges
  privileges = ["ALL"]
}

resource "aws_secretsmanager_secret" "db_credentials" {
  for_each = local.users

  name        = "/${var.cluster_name}/${each.value.name}/${each.value.env}/${each.value.db}"
  description = "Credentials for the Postgresql DB user ${each.key}"

  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "credentials" {
  for_each = local.users

  secret_id = aws_secretsmanager_secret.db_credentials[each.key].id

  secret_string = jsonencode({
    username = postgresql_role.user[each.key].name
    password = random_password.password[each.key].result
    engine   = "postgres"
    host     = var.postgresql_host
    port     = var.postgresql_port
  })
}
