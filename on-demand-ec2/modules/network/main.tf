terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = "ap-southeast-2"
}


data "aws_caller_identity" "current" {}

data "aws_vpc" "main_vpc" {
  filter {
    name   = "tag:Name"
    values = ["${data.aws_caller_identity.current.account_id}-VPC"]
  }
}

data "aws_subnets" "all_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main_vpc.id]
  }
}

data "aws_subnet" "all_subnet" {
  for_each = toset(data.aws_subnets.all_subnets.ids)
  id       = each.value
}
