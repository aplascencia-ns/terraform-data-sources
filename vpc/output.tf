output "vpc_id" {
  value = aws_vpc.this.id
}

# output "availability_zones" {
#   value = data.aws_availability_zones.available.names
# }

# output "igw_default" {
#   value = data.aws_internet_gateway.default.id
# }
