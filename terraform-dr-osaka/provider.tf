terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-3"

  default_tags {
    tags = {
      environment = "prod-dr"
      team        = "infra"
      service     = "shared-network"
      owner       = "team-2"
      auto-stop   = "false"
      created-by  = "terraform"
    }
  }
}
