terraform {
  # Keep this in sync with the FROM line in the Dockerfile
  required_version = "1.6.6"

  backend "s3" {
    key     = "tf_aurora_mysql.tfstate"
    encrypt = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.31"
    }

    mysql = {
      source  = "winebarrel/mysql"
      version = "~> 1.10.6"
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

provider "mysql" {
  endpoint = "${var.mysql_host}:${var.mysql_port}"
  username = var.mysql_credentials.username
  password = var.mysql_credentials.password
}
