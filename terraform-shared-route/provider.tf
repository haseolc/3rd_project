terraform {
  backend "s3" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-2"

  default_tags {
    tags = {
      environment = "sandbox"
      team        = "infra"
      owner       = "team-2"
      service     = "shared-network"
      auto-stop   = "false"
      created-by  = "terraform"
    }
  }
}
