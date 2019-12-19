output "availability_zones" {
  value = data.aws_availability_zones.available.names
}

output "vpc_default_cidr_block" {
  value = data.aws_vpc.default.cidr_block
}
output "vpc_default_id" {
  value = data.aws_vpc.default.id
}

output "subnet_ids" {
  value = data.aws_subnet_ids.default.*
}

output "subnet_1a" {
  value = data.aws_subnet.subnet_1a.*
}


