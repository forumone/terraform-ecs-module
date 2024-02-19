variable "name" {
  description = "Name of the cluster. Used to uniquely identify all resources related to this cluster"
  type        = string

  validation {
    condition     = length(regexall("^[-[:lower:][:digit:]]+$", var.name)) > 0
    error_message = "A cluster name must be an all-lowercase kebab-case identifier."
  }
}

variable "vpc" {
  description = "Options controlling VPC creation"

  type = object({
    cidr     = string
    az_count = number
  })
}

variable "networking" {
  description = "Options controlling networking and security groups"

  type = object({
    ingress_ports = optional(list(number), [])
  })

  default = {}
}

variable "dns" {
  description = "Options controlling public and private DNS"

  type = object({
    suffix   = string
    cloudmap = bool
  })
}

variable "acm" {
  description = "Options controlling ACM customization"

  type = object({
    certificates = optional(list(string), [])
  })

  default = {}
}

variable "mysql" {
  description = "Options controlling the Aurora MySQL cluster"

  type = object({
    engine_version      = string
    instance_type       = string
    replica_count       = number
    db_parameters       = optional(list(map(string)), [])
    db_parameter_family = string
  })

  default = null
}

variable "postgresql" {
  description = "Options controlling the Aurora PostgreSQL cluster"

  type = object({
    engine_version = string
    instance_type  = string
    replica_count  = number
  })

  default = null
}

variable "search" {
  description = "Options controlling the AWS OpenSearch cluster"

  type = object({
    engine_version       = string
    instance_type        = string
    instance_count       = number
    storage_size         = number
    storage_type         = optional(string, "gp2")
    storage_iops         = optional(number)
    storage_throughput   = optional(number)
    dedicated_node_count = optional(number, 0)
    dedicated_node_type  = optional(string)
    enable_logs          = optional(list(string), ["ES_APPLICATION_LOGS"])
  })

  default = null
}

variable "memcache" {
  description = "Options controlling the Elasticache Memcache cluster"

  type = object({
    engine_version       = string
    node_type            = string
    num_cache_nodes      = number
    parameter_group_name = string
  })

  default = null
}

variable "redis" {
  description = "Options controlling the Elasticache Redis cluster"

  type = object({
    engine_version     = string
    node_type          = string
    num_cache_clusters = number
    parameter_group    = string
  })

  default = null
}

variable "logs" {
  description = "Options controlling CloudWatch and S3 logging behavior"

  type = object({
    retention = optional(number, 30)
  })

  default = {}
}

variable "traefik" {
  description = "Options customizing the Traefik router service"

  type = object({
    repository   = optional(string)
    tag          = optional(string)
    version      = optional(string)
    log_level    = optional(string)
    min_capacity = optional(number)
    max_capacity = optional(number)
    config_file  = optional(string)
  })

  default = {}
}

variable "buildkite" {
  description = "Options indicating Buildkite roles for building/deploying"

  type = object({
    builders  = list(string)
    deployers = list(string)
  })
}

variable "backups" {
  description = "Options controlling backups behavior"

  type = object({
    retention = optional(number, 30)
  })

  default = {}
}

variable "rsync" {
  description = "Options for remote backups via rsync"

  type = object({
    username    = string
    hostname    = string
    fingerprint = string
  })
}

variable "applications" {
  description = "Application-specific configuration"

  type = list(object({
    name           = string
    environments   = map(list(string))
    containers     = list(string)
    acmSubdomain   = optional(bool, false)
    roles          = optional(list(string))
    buckets        = optional(list(string))
    services       = optional(list(string))
    logGroups      = optional(list(string))
    accessPoints   = optional(list(string))
    securityGroups = optional(list(string))

    databases = optional(object({
      mysql      = optional(list(string), [])
      postgresql = optional(list(string), [])
    }))
  }))
}

variable "tags" {
  description = "Tags to apply to created resources"
  type        = map(string)
  default     = {}
}
