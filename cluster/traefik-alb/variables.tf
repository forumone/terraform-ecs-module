variable "vpc_id" {
  description = "ID of the VPC in which Traefik will be deployed"
  type        = string
}

variable "alb_arn" {
  description = "ARN of the application load balancer Traefik will be accessed from"
  type        = string
}

variable "acm_default_cert_arn" {
  description = "ARN of the ACM certificate to apply to the HTTPS listener"
  type        = string
}

variable "acm_extra_cert_arns" {
  description = "List of additional certificates to apply to the HTTPS listener"
  type        = list(string)
  default     = []
}

variable "tls_policy" {
  description = "TLS policy to apply to the HTTPS listener"
  type        = string
  default     = "ELBSecurityPolicy-TLS-1-2-2017-01"
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster in which Traefik will be deployed"
  type        = string
}

variable "cloudwatch_log_retention" {
  description = "Number of days to retain logs in CloudWatch"
  type        = number
}

variable "alb_security_group_id" {
  description = "ID of the ALB's security group"
  type        = string
}

variable "private_subnets_ids" {
  description = "IDs of the private subnets in which Traefik will be launched"
  type        = list(string)
}

variable "task_cpu" {
  description = "CPU allocation for the ECS task"
  type        = number
  nullable    = false
  default     = 256
}

variable "task_memory" {
  description = "Memory allocation for the ECS task"
  type        = number
  nullable    = false
  default     = 512
}

variable "autoscaling_min" {
  description = "Minimum number of Traefik tasks to run"
  type        = number
  nullable    = false
  default     = 2
}

variable "autoscaling_max" {
  description = "Maximum number of Traefik tasks to run"
  type        = number
  nullable    = false
  default     = 4
}

variable "image_repository" {
  description = "Image repository from which to pull Traefik. Defaults to pulling from the Docker Hub"
  type        = string
  nullable    = false
  default     = "traefik"
}

variable "image_tag" {
  description = "Version tag of the Traefik container to use"
  type        = string
  nullable    = false
  default     = "latest"
}

variable "traefik_log_level" {
  description = "Log level for Traefik"
  type        = string
  nullable    = false
  default     = "ERROR"
}

variable "traefik_access_logs" {
  description = "Whether or not to enable access logging by Traefik"
  type        = bool
  nullable    = false
  default     = false
}

variable "configuration_file" {
  description = "Full path to a file to be copied into S3 and read"
  type        = string
  default     = null
}
