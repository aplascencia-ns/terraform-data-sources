# REQUIRE A SPECIFIC TERRAFORM VERSION OR HIGHER
# ------------------------------------------------------------------------------
terraform {
  required_version = ">= 0.12"
}

# Configure the provider(s)
provider "aws" {
  region = "us-east-1" # N. Virginia (US East)
}

################
# Data Sources
################
data "aws_availability_zones" "available" {}

################
# VPC
################
resource "aws_vpc" "this" {
  cidr_block           = var.network_cidr
  enable_dns_hostnames = true

  tags = {
    Name = "${var.cluster_name}_vpc"
  }
}

################
# Publiс Subnets
################
resource "aws_subnet" "public" {
  count = 2 # length(var.availability_zones)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.network_cidr, 8, count.index + 100)       # 10.0.0.0/24 
  availability_zone       = data.aws_availability_zones.available.names[count.index] # AZa
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.cluster_name}_public_${substr(element(data.aws_availability_zones.available.names, count.index), length(data.aws_availability_zones.available.names[count.index]) - 2, 2)}"
  }
}

################
# Private Subnets
################
resource "aws_subnet" "private" {
  count = 2 # length(var.availability_zones)

  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.network_cidr, 8, count.index) # + 2 because I created one public subnet
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.cluster_name}_private_${substr(element(data.aws_availability_zones.available.names, count.index), length(data.aws_availability_zones.available.names[count.index]) - 2, 2)}"
    # Name = "${var.cluster_name}_private_${count.index + 1}_${element(data.aws_availability_zones.available.names, count.index)}"
  }
}

###################
# Internet Gateway
###################
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.cluster_name}_igw"
  }
}

################
# Publiс Route Tables
################
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.cluster_name}_public_rt"
  }
}

resource "aws_route" "public_igw" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = local.all_ips # Destination
  gateway_id             = aws_internet_gateway.this.id
}

################
# Private Route Tables
################
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.cluster_name}_private_rt"
  }
}


##########################
# Route table association
##########################
# ######### Public Subnet  #############
resource "aws_route_table_association" "public" {
  count = 2

  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public.id
}

# ######### Private Subnet #############
resource "aws_route_table_association" "private" {
  count = 2

  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = aws_route_table.private.id
}



locals {
  any_port     = 0
  any_protocol = -1
  tcp_protocol = "tcp"
  all_ips      = "0.0.0.0/0"
  all_ips_list = ["0.0.0.0/0"]
}
