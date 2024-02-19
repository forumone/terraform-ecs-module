variable "cluster_name" {
  description = "ECS cluster Name"
  type        = string
}

variable "mysql_host" {
  description = "MySQL Host Name"
  type        = string
}

variable "mysql_port" {
  description = "MySQL Host Port"
  type        = number
}

variable "mysql_credentials" {
  description = "Username and password of the root MySQL user"

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
