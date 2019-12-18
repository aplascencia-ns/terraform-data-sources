output "vpc_id" {
  value = data.aws_vpc.main_vpc.id
}

# output "public_subnet_1" {
#   value = data.aws_subnet.subnet_public_1.*
# }

output "bastion_public_ip" {
  value = aws_instance.bastion.*
}

# output "public_subnet_1_cidr_block" {
#   value = data.aws_subnet.subnet_public_1.cidr_block
# }

