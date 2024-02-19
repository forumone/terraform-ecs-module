terraform {
  # Keep this in sync with the FROM line in the Dockerfile
  required_version = "1.6.6"

  backend "s3" {
    key     = "tf_aurora_postgresql.tfstate"
    encrypt = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.31"
    }

    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "~> 1.21.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "postgresql" {
  host            = var.postgresql_host
  port            = var.postgresql_port
  username        = var.postgresql_credentials.username
  password        = var.postgresql_credentials.password
  superuser       = false
  database        = "postgres"
  sslmode         = "require"
  connect_timeout = 15
}
