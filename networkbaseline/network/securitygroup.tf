resource "aws_security_group" "standard" {
  name = "mike-sg"
  description = "Standard rules"
  vpc_id = data.aws_vpc.main_vpc.id

  tags = {
    Name        = "mike-sg"
    ManagedBy   = "terraform"
  }
}

resource "aws_security_group_rule" "public_out" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
 
  security_group_id = aws_security_group.standard.id
}

resource "aws_security_group_rule" "ssh_10" {
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["10.0.0.0/8"]
 
  security_group_id = aws_security_group.standard.id
}

resource "aws_security_group_rule" "ssh_147" {
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["147.200.0.0/16"]
 
  security_group_id = aws_security_group.standard.id
}

resource "aws_security_group_rule" "rdp_10" {
  type        = "ingress"
  from_port   = 3389
  to_port     = 3389
  protocol    = "tcp"
  cidr_blocks = ["10.0.0.0/8"]
 
  security_group_id = aws_security_group.standard.id
}

resource "aws_security_group_rule" "rdp_147" {
  type        = "ingress"
  from_port   = 3389
  to_port     = 3389
  protocol    = "tcp"
  cidr_blocks = ["147.200.0.0/16"]
 
  security_group_id = aws_security_group.standard.id
}

resource "aws_security_group_rule" "icmp_10" {
  type        = "ingress"
  from_port   = 8
  to_port     = 8
  protocol    = "icmp"
  cidr_blocks = ["10.0.0.0/8"]
 
  security_group_id = aws_security_group.standard.id
}

resource "aws_security_group_rule" "icmp_147" {
  type        = "ingress"
  from_port   = 8
  to_port     = 8
  protocol    = "icmp"
  cidr_blocks = ["147.200.0.0/16"]
 
  security_group_id = aws_security_group.standard.id
}

resource "aws_security_group_rule" "all_zones" {
  
  for_each = data.aws_subnet.all_subnet
  type        = "ingress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = [each.value.cidr_block]
  description = each.value.tags["Name"]
 
  security_group_id = aws_security_group.standard.id
}



