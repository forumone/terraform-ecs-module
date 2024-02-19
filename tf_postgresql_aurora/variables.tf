variable "cluster_name" {
  description = "ECS cluster Name"
  type        = string
}

variable "postgresql_host" {
  description = "PostgreSQL Host Name"
  type        = string
}

variable "postgresql_port" {
  description = "postgresql Host Port"
  type        = number
}

variable "postgresql_credentials" {
  description = "Username and password of the root postgresql user"

  type = object({
    username = string
    password = string
  })
}

variable "aws_region" {
  description = "Name of the AWS region in which this container is running"
  type        = string
}

variable "databases" {
  description = "List of databases to be created"
  type = list(object({
    name = string
    env  = string
    db   = string
  }))
}
