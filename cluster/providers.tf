terraform {
  required_version = "~> 1.6.6"

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.31"
      configuration_aliases = [
        aws.infrastructure
     ]
    }

    tls = {
      source  = "hashicorp/tls"
      version = "4.0.5"
    }
  }
}
