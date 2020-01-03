output "vpc_id" {
  value = aws_vpc.this.id
}

output "availability_zones" {
  value = data.aws_availability_zones.available.names
}

# output "azs" {
#   count = 2
#   value = substr(element(data.aws_availability_zones.available.names, count.index), length(element(data.aws_availability_zones.available.names, count.index) - 2), 2)
# }
