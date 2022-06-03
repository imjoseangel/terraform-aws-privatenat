terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.17.0"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region = var.region
}
