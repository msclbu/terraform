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





resource "random_id" "id" {
	byte_length = 8
}



resource "aws_instance" "amzn2" {

  depends_on = [aws_security_group.ec2_sg1]
  ami           = "ami-02a66f06b3557a897"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.ec2_sg1.id]
  subnet_id = data.aws_subnet.subnet_a.id
  tags = {
    Name = "mike-amzn2-${random_id.id.hex}"
  }
}
