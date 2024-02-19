<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | 1.6.6 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.31 |
| <a name="requirement_mysql"></a> [mysql](#requirement\_mysql) | ~> 1.10.6 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.6 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.31 |
| <a name="provider_mysql"></a> [mysql](#provider\_mysql) | ~> 1.10.6 |
| <a name="provider_random"></a> [random](#provider\_random) | ~> 3.6 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_secretsmanager_secret.db_credentials](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.credentials](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [mysql_database.database](https://registry.terraform.io/providers/winebarrel/mysql/latest/docs/resources/database) | resource |
| [mysql_grant.grant](https://registry.terraform.io/providers/winebarrel/mysql/latest/docs/resources/grant) | resource |
| [mysql_user.user](https://registry.terraform.io/providers/winebarrel/mysql/latest/docs/resources/user) | resource |
| [random_password.password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | Name of the AWS region in which this container is running | `string` | n/a | yes |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | ECS cluster Name | `string` | n/a | yes |
| <a name="input_databases"></a> [databases](#input\_databases) | List of databases to be created | <pre>list(object({<br>    name = string<br>    env  = string<br>    db   = string<br>  }))</pre> | n/a | yes |
| <a name="input_mysql_credentials"></a> [mysql\_credentials](#input\_mysql\_credentials) | Username and password of the root MySQL user | <pre>object({<br>    username = string<br>    password = string<br>  })</pre> | n/a | yes |
| <a name="input_mysql_host"></a> [mysql\_host](#input\_mysql\_host) | MySQL Host Name | `string` | n/a | yes |
| <a name="input_mysql_port"></a> [mysql\_port](#input\_mysql\_port) | MySQL Host Port | `number` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->