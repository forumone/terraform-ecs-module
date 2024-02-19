# Create Users List
locals {
  users = {
    for database in var.databases : "${database.name}-${database.env}-${database.db}" =>
    database
  }
}

resource "mysql_database" "database" {
  for_each = local.users

  name = each.key
}

resource "random_password" "password" {
  for_each = local.users
  special  = false
  length   = 20
}

resource "mysql_user" "user" {
  for_each = local.users

  user               = mysql_database.database[each.key].name
  host               = "%"
  plaintext_password = random_password.password[each.key].result
}

resource "mysql_grant" "grant" {
  for_each = local.users

  user       = mysql_user.user[each.key].user
  host       = mysql_user.user[each.key].host
  database   = mysql_database.database[each.key].name
  privileges = ["ALL PRIVILEGES"]
}

resource "aws_secretsmanager_secret" "db_credentials" {
  for_each = local.users

  name        = "/${var.cluster_name}/${each.value.name}/${each.value.env}/${each.value.db}"
  description = "Credentials for the DB user ${each.key}"

  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "credentials" {
  for_each = local.users

  secret_id = aws_secretsmanager_secret.db_credentials[each.key].id

  secret_string = jsonencode({
    username = mysql_user.user[each.key].user
    password = random_password.password[each.key].result
    engine   = "mysql"
    host     = var.mysql_host
    port     = var.mysql_port
  })
}
