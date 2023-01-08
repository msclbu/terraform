# output "all_subnets" {
#   value = data.aws_subnets.all_subnets
# }

# output "all_subnet" {
#   value = data.aws_subnet.all_subnet
# }

# output "main_vpc"{
#     value = data.aws_vpc.main_vpc
# }

# output "subnet_cidr_blocks" {
#   value = [for s in data.aws_subnet.all_subnet: s.cidr_block]
# }

# output "subnet_names"{
#     value = [for s in data.aws_subnet.all_subnet : s.tags["Name"]]
# }

output "ec2_sg1"{
    description = "Security Group for EC2 Instance"
    value = aws_security_group.standard
}