output "vpc_id" {
  value = aws_vpc.main_vpc.id
}

output "availability_zones" {
  value = data.aws_availability_zones.available.names
}
