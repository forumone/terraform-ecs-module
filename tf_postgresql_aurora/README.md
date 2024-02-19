<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | 1.6.6 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.31 |
| <a name="requirement_postgresql"></a> [postgresql](#requirement\_postgresql) | ~> 1.21.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.6 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.31 |
| <a name="provider_postgresql"></a> [postgresql](#provider\_postgresql) | ~> 1.21.0 |
| <a name="provider_random"></a> [random](#provider\_random) | ~> 3.6 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_secretsmanager_secret.db_credentials](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.credentials](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [postgresql_database.database](https://registry.terraform.io/providers/cyrilgdn/postgresql/latest/docs/resources/database) | resource |
| [postgresql_grant.database_privileges](https://registry.terraform.io/providers/cyrilgdn/postgresql/latest/docs/resources/grant) | resource |
| [postgresql_role.user](https://registry.terraform.io/providers/cyrilgdn/postgresql/latest/docs/resources/role) | resource |
| [random_password.password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | Name of the AWS region in which this container is running | `string` | n/a | yes |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | ECS cluster Name | `string` | n/a | yes |
| <a name="input_databases"></a> [databases](#input\_databases) | List of databases to be created | <pre>list(object({<br>    name = string<br>    env  = string<br>    db   = string<br>  }))</pre> | n/a | yes |
| <a name="input_postgresql_credentials"></a> [postgresql\_credentials](#input\_postgresql\_credentials) | Username and password of the root postgresql user | <pre>object({<br>    username = string<br>    password = string<br>  })</pre> | n/a | yes |
| <a name="input_postgresql_host"></a> [postgresql\_host](#input\_postgresql\_host) | PostgreSQL Host Name | `string` | n/a | yes |
| <a name="input_postgresql_port"></a> [postgresql\_port](#input\_postgresql\_port) | postgresql Host Port | `number` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->