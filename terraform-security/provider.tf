terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {}
}

provider "aws" {
  region = "ap-northeast-2"
}