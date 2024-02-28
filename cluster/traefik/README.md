<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.3 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.37 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.37 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_s3_traefik"></a> [s3\_traefik](#module\_s3\_traefik) | terraform-aws-modules/s3-bucket/aws | ~> 4.0.1 |

## Resources

| Name | Type |
|------|------|
| [aws_appautoscaling_policy.traefik](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_policy) | resource |
| [aws_appautoscaling_target.traefik](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_target) | resource |
| [aws_cloudwatch_log_group.traefik](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_ecs_service.traefik](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_task_definition.traefik](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_iam_policy.traefik_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.traefik_exec](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.traefik_task](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.traefik_exec](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.traefik_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lb_listener.traefik_http](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener.traefik_https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener_certificate.traefik_https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_certificate) | resource |
| [aws_lb_target_group.traefik_http](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_lb_target_group.traefik_https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_s3_object.traefik_configuration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_security_group.traefik](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.public_traefik_http_ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.public_traefik_https_ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.traefik_https_egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_iam_policy_document.ecs_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.traefik_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_acm_default_cert_arn"></a> [acm\_default\_cert\_arn](#input\_acm\_default\_cert\_arn) | ARN of the ACM certificate to apply to the HTTPS listener | `string` | n/a | yes |
| <a name="input_cloudwatch_log_retention"></a> [cloudwatch\_log\_retention](#input\_cloudwatch\_log\_retention) | Number of days to retain logs in CloudWatch | `number` | n/a | yes |
| <a name="input_ecs_cluster_name"></a> [ecs\_cluster\_name](#input\_ecs\_cluster\_name) | Name of the ECS cluster in which Traefik will be deployed | `string` | n/a | yes |
| <a name="input_nlb_arn"></a> [nlb\_arn](#input\_nlb\_arn) | ARN of the network load balancer Traefik will be accessed from | `string` | n/a | yes |
| <a name="input_private_subnets_ids"></a> [private\_subnets\_ids](#input\_private\_subnets\_ids) | IDs of the private subnets in which Traefik will be launched | `list(string)` | n/a | yes |
| <a name="input_public_subnets_ipv4"></a> [public\_subnets\_ipv4](#input\_public\_subnets\_ipv4) | IPv4 CIDR ranges of the VPC's public subnets | `list(string)` | n/a | yes |
| <a name="input_public_subnets_ipv6"></a> [public\_subnets\_ipv6](#input\_public\_subnets\_ipv6) | IPv6 CIDR ranges of the VPC's public subnets | `list(string)` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of the VPC in which Traefik will be deployed | `string` | n/a | yes |
| <a name="input_acm_extra_cert_arns"></a> [acm\_extra\_cert\_arns](#input\_acm\_extra\_cert\_arns) | List of additional certificates to apply to the HTTPS listener | `list(string)` | `[]` | no |
| <a name="input_autoscaling_max"></a> [autoscaling\_max](#input\_autoscaling\_max) | Maximum number of Traefik tasks to run | `number` | `4` | no |
| <a name="input_autoscaling_min"></a> [autoscaling\_min](#input\_autoscaling\_min) | Minimum number of Traefik tasks to run | `number` | `2` | no |
| <a name="input_configuration_file"></a> [configuration\_file](#input\_configuration\_file) | Full path to a file to be copied into S3 and read | `string` | `null` | no |
| <a name="input_http_port"></a> [http\_port](#input\_http\_port) | HTTP port for Traefik to listen on | `number` | `80` | no |
| <a name="input_https_port"></a> [https\_port](#input\_https\_port) | HTTPS port for Traefik to listen on | `number` | `443` | no |
| <a name="input_image_repository"></a> [image\_repository](#input\_image\_repository) | Image repository from which to pull Traefik. Defaults to pulling from the Docker Hub | `string` | `"traefik"` | no |
| <a name="input_image_tag"></a> [image\_tag](#input\_image\_tag) | Version tag of the Traefik container to use | `string` | `"latest"` | no |
| <a name="input_task_cpu"></a> [task\_cpu](#input\_task\_cpu) | CPU allocation for the ECS task | `number` | `256` | no |
| <a name="input_task_memory"></a> [task\_memory](#input\_task\_memory) | Memory allocation for the ECS task | `number` | `512` | no |
| <a name="input_tls_policy"></a> [tls\_policy](#input\_tls\_policy) | TLS policy to apply to the HTTPS listener | `string` | `"ELBSecurityPolicy-TLS-1-2-2017-01"` | no |
| <a name="input_traefik_access_logs"></a> [traefik\_access\_logs](#input\_traefik\_access\_logs) | Whether or not to enable access logging by Traefik | `bool` | `false` | no |
| <a name="input_traefik_log_level"></a> [traefik\_log\_level](#input\_traefik\_log\_level) | Log level for Traefik | `string` | `"ERROR"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_http_lb_listener_arn"></a> [http\_lb\_listener\_arn](#output\_http\_lb\_listener\_arn) | The Traefik HTTP Listener ARN |
| <a name="output_http_target_group_arn"></a> [http\_target\_group\_arn](#output\_http\_target\_group\_arn) | The Traefik HTTP Target |
| <a name="output_https_lb_listener_arn"></a> [https\_lb\_listener\_arn](#output\_https\_lb\_listener\_arn) | The Traefik HTTPS Listener ARN |
| <a name="output_https_target_group_arn"></a> [https\_target\_group\_arn](#output\_https\_target\_group\_arn) | The Traefik HTTPS Target |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | The Security Group IP of the Traefik ECS Security Group |
| <a name="output_traefik_ecs_service_id"></a> [traefik\_ecs\_service\_id](#output\_traefik\_ecs\_service\_id) | The Traefik ECS Service ID |
| <a name="output_traefik_ecs_task_arn"></a> [traefik\_ecs\_task\_arn](#output\_traefik\_ecs\_task\_arn) | The Traefik ECS Task ARN |
| <a name="output_traefik_ecs_task_revision"></a> [traefik\_ecs\_task\_revision](#output\_traefik\_ecs\_task\_revision) | The Traefik ECS Task Revision |
<!-- END_TF_DOCS -->