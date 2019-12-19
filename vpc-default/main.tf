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

# To get the data out of a data source,
data "aws_vpc" "default" {
  default = true
}

# You can combine this with another data source
data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

data "aws_subnet" "subnet_1a" {
  filter {
    name   = "tag:Name"
    values = ["subnet-1a"]       # insert value here
  }
}
