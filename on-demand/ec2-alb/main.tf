terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
}

provider "aws" {
  region = "ap-southeast-2"
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

data "aws_caller_identity" "current" {}

data "aws_vpc" "main_vpc" {
  filter {
    name   = "tag:Name"
    values = ["${data.aws_caller_identity.current.account_id}-VPC"]
  }
}

data "aws_internet_gateway" "main" {
  filter {
    name   = "tag:Name"
    values = ["test-igw"]
  }
}

resource "aws_subnet" "subnet1" {
  vpc_id            = data.aws_vpc.main_vpc.id
  cidr_block        = cidrsubnet(var.cidr_block, 8, 7)
  availability_zone = var.availability_zones[0]

  tags = {
    Name = "ALB-PublicSubnet1"
    Type = "Public"
  }
}

resource "aws_subnet" "subnet2" {
  vpc_id            = data.aws_vpc.main_vpc.id
  cidr_block        = cidrsubnet(var.cidr_block, 8, 8)
  availability_zone = var.availability_zones[1]

  tags = {
    Name = "ALB-PublicSubnet2"
    Type = "Public"
  }
}

resource "aws_subnet" "subnet3" {
  vpc_id            = data.aws_vpc.main_vpc.id
  cidr_block        = cidrsubnet(var.cidr_block, 8, 9)
  availability_zone = var.availability_zones[0]

  tags = {
    Name = "ALB-PrivateSubnet3"
    Type = "Private"
  }
}

resource "aws_subnet" "subnet4" {
  vpc_id            = data.aws_vpc.main_vpc.id
  cidr_block        = cidrsubnet(var.cidr_block, 8, 10)
  availability_zone = var.availability_zones[1]

  tags = {
    Name = "ALB-PrivateSubnet4"
    Type = "Private"
  }
}


resource "aws_eip" "nat" {
  vpc = true
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.subnet1.id

  tags = {
    Name = "NAT"
  }

}

resource "aws_route_table" "rt1" {
  vpc_id = data.aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = data.aws_internet_gateway.main.id
  }

  tags = {
    Name = "Public"
  }
}

resource "aws_route_table" "rt2" {
  vpc_id = data.aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "Private"
  }
}

resource "aws_route_table_association" "rta1" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.rt1.id
}

resource "aws_route_table_association" "rta2" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.rt1.id
}

resource "aws_route_table_association" "rta3" {
  subnet_id      = aws_subnet.subnet3.id
  route_table_id = aws_route_table.rt2.id
}

resource "aws_route_table_association" "rta4" {
  subnet_id      = aws_subnet.subnet4.id
  route_table_id = aws_route_table.rt2.id
}

resource "aws_security_group" "webserver" {
  name        = "WebServer"
  description = "WebServer Traffic"
  vpc_id      = data.aws_vpc.main_vpc.id

  ingress {
    description = "SSH from workstation"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.workstation_ip]
  }

  ingress {
    description = "80 from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [
      cidrsubnet(var.cidr_block, 8, 1),
      cidrsubnet(var.cidr_block, 8, 2)
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow traffic"
  }
}

resource "aws_security_group" "alb" {
  name        = "ALB"
  description = "ALB Traffic"
  vpc_id      = data.aws_vpc.main_vpc.id

  ingress {
    description = "80 from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.webserver.id]
  }

  tags = {
    Name = "ALB Allow Traffic"
  }
}

resource "aws_launch_template" "launchtemplate1" {
  name = "web"

  image_id               = data.aws_ami.amazon2.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.webserver.id]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "WebServer"
    }
  }


}

resource "aws_lb" "alb1" {
  name               = "alb1"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]

  enable_deletion_protection = false

  tags = {
    Environment = "Dev"
  }
}

resource "aws_alb_target_group" "webserver" {
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.main_vpc.id
}

resource "aws_alb_listener" "front_end" {
  load_balancer_arn = aws_lb.alb1.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.webserver.arn
  }
}

resource "aws_alb_listener_rule" "rule1" {
  listener_arn = aws_alb_listener.front_end.arn
  priority     = 99

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.webserver.arn
  }

  condition {
    path_pattern {
      values = ["/"]
    }
  }
}

resource "aws_autoscaling_group" "asg" {
  vpc_zone_identifier = [aws_subnet.subnet3.id, aws_subnet.subnet4.id]

  desired_capacity = 2
  max_size         = 2
  min_size         = 2

  target_group_arns = [aws_alb_target_group.webserver.arn]

  launch_template {
    id      = aws_launch_template.launchtemplate1.id
    version = "$Latest"
  }
}