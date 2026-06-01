terraform {
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
      service     = "shared-network"
      owner       = "team-leader"
      auto-stop   = "true"
      created-by  = "terraform"
    }
  }
}
