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
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "${var.cluster_name}-main-vpc"
  }
}


# variable "vpc_id" {}

data "aws_vpc" "main_vpc" {
  id = aws_vpc.main_vpc.id
}

# variable "subnet1" {
#   type = string
#   default = "${var.cluster_name}_Public-Subnet-1"
# }


# data "aws_subnet" "subnet_public_1" {
#   filter {
#     name = "tag:Name"
#     # values = ["webservers-VPC_Public-*"]
#     values = ["webservers-VPC_Public-Subnet-1"] # insert value here
#   }
# }
# resource "aws_subnet" "example" {
#   vpc_id            = "${data.aws_vpc.selected.id}"
#   availability_zone = "us-east-1a"
#   cidr_block        = "${cidrsubnet(data.aws_vpc.selected.cidr_block, 4, 1)}"
# }


# PUBLIC SUBNETS
# --------------------------------------
resource "aws_subnet" "public_subnet" {
  count             = 1 # length(var.availability_zones)
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = cidrsubnet(var.network_cidr, 8, count.index)             # 10.0.0.0/24 
  availability_zone = data.aws_availability_zones.available.names[count.index] # AZa

  # availability_zone = element(var.availability_zones, count.index)
  # availability_zone = element(data.aws_availability_zones.all.names, count.index)

  tags = {
    Name = "${var.cluster_name}_Public-Subnet-${count.index + 1}" #-${element(data.aws_availability_zones.available.names, count.index)}"
  }
}

# PRIVATE SUBNETS
# --------------------------------------
resource "aws_subnet" "private_subnet" {
  count             = 1 # length(var.availability_zones)
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = cidrsubnet(var.network_cidr, 8, count.index + 1) # + 2 because I created one public subnet
  availability_zone = data.aws_availability_zones.available.names[count.index]


  # availability_zone = element(var.availability_zones, count.index)

  tags = {
    Name = "${var.cluster_name}_Private-Subnet-${count.index + 1}" #-${element(data.aws_availability_zones.available.names, count.index)}"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# BASTION HOST
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_instance" "bastion" {
  ami                         = "ami-00068cd7555f543d5" # data.aws_ami.ubuntu_18_04.id # "ami-969ab1f6"
  key_name                    = aws_key_pair.bastion_key.key_name
  instance_type               = var.instance_type #"t2.micro"
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  subnet_id                   = aws_subnet.public_subnet[0].id
  associate_public_ip_address = true

  tags = {
    Name = "${var.cluster_name}-bastion"
  }
}

resource "aws_security_group" "bastion_sg" {
  name        = "${var.cluster_name}-bastion-sg"
  vpc_id      = aws_vpc.main_vpc.id
  description = "Enter SG for bastion host. SSH access only"
}

resource "aws_security_group_rule" "allow_ssh_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.bastion_sg.id

  protocol    = "tcp"
  from_port   = 22
  to_port     = 22
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  security_group_id = aws_security_group.bastion_sg.id

  protocol    = -1
  from_port   = 0
  to_port     = 0
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_bastion_private_sg_outbound" {
  type              = "egress"
  security_group_id = aws_security_group.bastion_sg.id

  protocol                 = "tcp"
  from_port                = 22
  to_port                  = 22
  source_security_group_id = aws_security_group.bastion_private_sg.id
}


resource "aws_security_group" "bastion_private_sg" {
  name        = "${var.cluster_name}-bastion-private-sg"
  vpc_id      = aws_vpc.main_vpc.id
  description = "Security group for private instances. SSH inbound requests from Bastion host only."
}

resource "aws_security_group_rule" "allow_bastion_sg_outbound" {
  type              = "ingress"
  security_group_id = aws_security_group.bastion_private_sg.id

  protocol                 = "tcp"
  from_port                = 22
  to_port                  = 22
  source_security_group_id = aws_security_group.bastion_sg.id
}

resource "aws_security_group_rule" "allow_all_bastion_private_sg_outbound" {
  type              = "egress"
  security_group_id = aws_security_group.bastion_private_sg.id

  protocol    = -1
  from_port   = 0
  to_port     = 0
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_key_pair" "bastion_key" {
  key_name   = "id_rsa"
  public_key = var.key_pair
}






# ---------------------------------------------------------------------------------------------------------------------
#  NETWORKING
# ---------------------------------------------------------------------------------------------------------------------
############# Internet Gateway
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "${var.cluster_name}-main-igw"
  }
}

# ########### NACL ##############
resource "aws_network_acl" "private_nacl" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "${var.cluster_name}-private-nacl"
  }
}

# Rules INBOUND
resource "aws_network_acl_rule" "allow_ssh_inbound" {
  egress         = false
  network_acl_id = aws_network_acl.private_nacl.id

  rule_number = 100
  protocol    = "tcp"
  rule_action = "allow"
  cidr_block  = aws_subnet.private_subnet[0].cidr_block
  from_port   = 22
  to_port     = 22
}

resource "aws_network_acl_rule" "allow_custom_inbound" {
  egress         = false
  network_acl_id = aws_network_acl.private_nacl.id

  rule_number = 200
  protocol    = "tcp"
  rule_action = "allow"
  cidr_block  = aws_subnet.private_subnet[0].cidr_block
  from_port   = 32768
  to_port     = 65535
}

# Rules OUTBOUND
resource "aws_network_acl_rule" "allow_nacl_HTTP_outbound" {
  egress         = true
  network_acl_id = aws_network_acl.private_nacl.id

  rule_number = 100
  protocol    = "tcp"
  rule_action = "allow"
  cidr_block  = aws_subnet.private_subnet[0].cidr_block
  from_port   = 80
  to_port     = 80
}

resource "aws_network_acl_rule" "allow_nacl_HTTPS_outbound" {
  egress         = true
  network_acl_id = aws_network_acl.private_nacl.id

  rule_number = 200
  protocol    = "tcp"
  rule_action = "allow"
  cidr_block  = aws_subnet.private_subnet[0].cidr_block
  from_port   = 443
  to_port     = 443
}

resource "aws_network_acl_rule" "allow_nacl_custom_outbound" {
  egress         = true
  network_acl_id = aws_network_acl.private_nacl.id

  rule_number = 300
  protocol    = "tcp"
  rule_action = "allow"
  cidr_block  = aws_subnet.private_subnet[0].cidr_block
  from_port   = 32768
  to_port     = 65535
}


# ########### NAT ##############
# resource "aws_eip" "forNat_eip" {
#   vpc = true

#   tags = {
#     Name = "${var.cluster_name}-eip"
#   }
# }

# resource "aws_nat_gateway" "main_nat_gw" {
# #   count         = 2
#   allocation_id = aws_eip.forNat_eip.id
#   subnet_id = aws_subnet.public_subnet[0].id
# #   subnet_id     = element(aws_subnet.public_subnet.*.id, count.index)
#   depends_on    = [aws_internet_gateway.main_igw]

#   tags = {
#     Name = "${var.cluster_name}-main-nat-gw"
#   }
# }


# ############# Route Tables ##########
# PUBLIC Route table: attach Internet Gateway 
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"                      # Destination
    gateway_id = aws_internet_gateway.main_igw.id # Target
  }

  tags = {
    Name = "${var.cluster_name}-public-rt"
  }
}

# PRIVATE Route table: 
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id # aws_nat_gateway.main_nat_gw.id
  }

  tags = {
    Name = "${var.cluster_name}-private-rt"
  }
}


# ######### PUBLIC Subnet assiosation with rotute table    ######
resource "aws_route_table_association" "public_rta" {
  count          = 1
  subnet_id      = element(aws_subnet.public_subnet.*.id, count.index) #aws_subnet.public_subnet.id 
  route_table_id = aws_route_table.public_rt.id
}

# ########## PRIVATE Subnets assiosation with rotute table ######
resource "aws_route_table_association" "private_rta" {
  count          = 1
  subnet_id      = element(aws_subnet.private_subnet.*.id, count.index) # "aws_subnet.private_subnet.*" #element(aws_subnet.private_subnet.*.id, count.index) # aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_rt.id
}
