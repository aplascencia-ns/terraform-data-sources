# REQUIRE A SPECIFIC TERRAFORM VERSION OR HIGHER
# ------------------------------------------------------------------------------
terraform {
  required_version = ">= 0.12"
}

# Configure the provider(s)
provider "aws" {
  region = "us-east-1" # N. Virginia (US East)
}

# ---------------------------------------------------------------------------------------------------------------------
#  Get DATA SOURCES
# ---------------------------------------------------------------------------------------------------------------------
data "aws_availability_zones" "available" {}

# ---------------------------------------------------------------------------------------------------------------------
#  VPC AND SUBNETS
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_vpc" "main_vpc" {
  cidr_block           = var.network_cidr
  enable_dns_hostnames = true

  tags = {
    Name = "${var.cluster_name}-main-vpc"
  }
}

# PUBLIC SUBNETS
# --------------------------------------
resource "aws_subnet" "public_subnet" {
  count             = 2 # length(var.availability_zones)
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = cidrsubnet(var.network_cidr, 8, count.index)             # 10.0.0.0/24 
  availability_zone = data.aws_availability_zones.available.names[count.index] # AZa

  tags = {
    Name = "${var.cluster_name}_Public-Subnet-${count.index + 1}" #-${element(data.aws_availability_zones.available.names, count.index)}"
  }
}

# PRIVATE SUBNETS
# --------------------------------------
resource "aws_subnet" "private_subnet" {
  count             = 2 # length(var.availability_zones)
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = cidrsubnet(var.network_cidr, 8, count.index + 1) # + 2 because I created one public subnet
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.cluster_name}_Private-Subnet-${count.index + 1}" #-${element(data.aws_availability_zones.available.names, count.index)}"
  }
}
