

output "ec2_sg1"{
    description = "Security Group for EC2 Instance"
    value = aws_security_group.standard
}