terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.6.0"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region = "eu-west-1"
}
