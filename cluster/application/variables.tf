variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "cloudwatch_retention" {
  description = "Retention period for Cloudwatch logs"
  type        = number
}

variable "backup_retention" {
  description = "Retention period for backed-up objects (e.g., noncurrent S3 versions)"
  type        = number
}

variable "vpc_id" {
  description = "ID of the VPC in which resources are created"
  type        = string
}

variable "vpc_private_subnets" {
  description = "The VPC's private subnets"
  type        = list(string)
}

variable "vpc_availability_zones" {
  description = "The VPC's availability zones"
  type        = list(string)
}

variable "efs_security_group" {
  description = "Security group ID for EFS file systems"
  type        = string
}

variable "cloudmap_namespace" {
  description = "AWS Cloud Map namespace"
  type        = string
}

variable "application" {
  description = "Object defining application configuration"

  # Properties of this object:
  # * name: Name of this application, in kebab-case format
  # * environmenst: Mapping of cluster name => list of names (e.g.,
  #   {cluster-preprod: [dev, stage]})
  # * containers: List of container names for this application. An ECR
  #   repository will be created for each container listed here, and log groups
  #   for each combination of container and environment name.
  # * roles: List of IAM roles to create for each environment. No policies are
  #   automatically attached to these roles.
  # * buckets: List of S3 buckets to create for each environment. These are only
  #   partially managed; versioning and at-rest encryption are enabled but no
  #   other features are controlled.
  # * services: List of private DNS services to create for each environment
  # * logGroups: List of log groups to create for each environment. Used for
  #   off-the-shelf containers such as the New Relic sidecar.
  # * accessPoints: List of EFS access points to create for each environment. If
  #   omitted or empty, no EFS file system will be created.
  # * securityGroups: List of custom security groups to create for this
  #   application. These have no rules generated for them, as they are intended
  #   to supplement the default cluster-wide security group.
  type = object({
    name           = string
    environments   = map(list(string))
    containers     = list(string)
    roles          = optional(list(string), [])
    buckets        = optional(list(string), [])
    services       = optional(list(string), [])
    logGroups      = optional(list(string), [])
    accessPoints   = optional(list(string), [])
    securityGroups = optional(list(string), [])
  })

  validation {
    condition     = length(var.application.containers) > 0
    error_message = "var.application.containers must have at least one container name."
  }
}

variable "tags" {
  description = "Tags to apply to all created resources"
  type        = map(string)
  default     = {}
}
