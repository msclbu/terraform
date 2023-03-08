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


data "aws_ami" "amazon2" {
  most_recent = true

  filter {
    name = "name"
    values = ["amzn2-ami-*-hvm-*-x86_64-gp2"]
  }

  filter {
    name = "architecture"
    values = ["x86_64"]
  }

  owners = ["amazon"]
}




resource "random_id" "id" {
	byte_length = 8
}

data "aws_subnet" "controlled_subnet" {
  filter {
    name   = "tag:Name"
    values = [var.ec2_subnet]
  }
}

data "aws_security_group" "sg" {
  filter {
    name   = "tag:Name"
    values = [var.ec2_sg]
  }
}



resource "aws_instance" "amzn2" {

  ami           = data.aws_ami.amazon2.id
  instance_type = "t2.micro"
  security_groups = [data.aws_security_group.sg.id]
  subnet_id = data.aws_subnet.controlled_subnet.id
  tags = {
    Name = "mike-amzn2-${random_id.id.hex}"
  }
}
