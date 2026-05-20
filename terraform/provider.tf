# provider.tf

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0"
}

# 일본 도쿄 리전 세팅
provider "aws" {
  region = "ap-northeast-1"
}