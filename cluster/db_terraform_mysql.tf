# build the MySQL database list
locals {
  # Create a map of mysql datbases with a unique key, with 'env' and 'db'
  # properties:
  # * env: the name of the environment (e.g., "dev" or "www")
  # * db: the name of the access point (e.g., "web" or "gis")
  mysql_dbs = flatten([
    for application in var.applications : [
      for pair in setproduct(try(application.environments[var.name], []), try(application.databases.mysql, [])) :
      {
        name = application.name
        env  = pair[0]
        db   = pair[1]
      }
    ]
  ])
}

# ECS Task
resource "aws_ecs_task_definition" "terraform_mysql_database_exec" {
  count  = var.mysql == null ? 0 : 1
  family = "${var.name}-terraform-mysql-database-creation"

  task_role_arn      = aws_iam_role.terraform_database_task.arn
  execution_role_arn = aws_iam_role.terraform_database_exec.arn

  network_mode = "awsvpc"

  requires_compatibilities = ["FARGATE"]

  cpu    = 256
  memory = 1024

  container_definitions = jsonencode([
    {
      name = "terraform"
      # This will need to be updated with the correct repo
      image = "public.ecr.aws/forumone/ecs-terraform-mysql:latest"

      environment = [
        # See terraform/database/variables.tf for more on these
        { name = "TF_VAR_aws_region", value = data.aws_region.current.name },
        # Pass in the MySQL provider's endpoint; see https://registry.terraform.io/providers/winebarrel/mysql/latest/docs#argument-reference
        { name = "TF_VAR_mysql_host", value = module.mysql[0].cluster_endpoint },
        { name = "TF_VAR_mysql_port", value = tostring(module.mysql[0].cluster_port) },
        # Pass in list of databases to be created
        { name = "TF_VAR_databases", value = jsonencode(local.mysql_dbs) },
        # See terraform/database/README.md for more on why these are regular env vars
        { name = "BACKEND_STORAGE", value = module.s3_tfstate.s3_bucket_id },
        { name = "BACKEND_LOCKS", value = aws_dynamodb_table.terraform_locks.id },
        { name = "TF_VAR_cluster_name", value = module.ecs.cluster_name },
      ]

      secrets = [
        # Bind in the DB credentials as a TF variable. We do this because using keys from
        # inside a JSON-formatted secret is not yet supported in Fargate's LATEST version
        # (only 1.4.0), and this isn't so onerous that we can't work around it to simplify
        # the AWS CLI's run-task invocation needed to bootstrap the database secrets.
        { name = "TF_VAR_mysql_credentials", valueFrom = aws_secretsmanager_secret.mysql_root_credentials[0].arn }
      ]

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          awslogs-group         = aws_cloudwatch_log_group.terraform.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "terraform-mysql-aurora"
        }
      }
    }
  ])
}
