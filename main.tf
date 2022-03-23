#-------------------------------
# Read VPC
#-------------------------------
data "aws_vpcs" "main" {
  filter {
    name   = "tag:Name"
    values = var.vpc_name
  }
}

data "aws_availability_zones" "main" {
  state = "available"
}

data "aws_subnets" "main" {
  filter {
    name   = "tag:Name"
    values = var.subnets_spoke_names
  }
}

#-------------------------------
# Create Secondary CIDR
#-------------------------------
resource "aws_vpc_ipv4_cidr_block_association" "main" {
  vpc_id     = data.aws_vpcs.main.ids[0]
  cidr_block = var.vpc_cidr
}

#-------------------------------
# Calculate Subnets
#-------------------------------
module "subnet_addrs" {
  source  = "hashicorp/subnets/cidr"
  version = "1.0.0"

  base_cidr_block = aws_vpc_ipv4_cidr_block_association.main.cidr_block

  networks = [
    {
      name     = data.aws_availability_zones.main.names[0]
      new_bits = 9
    },
    {
      name     = data.aws_availability_zones.main.names[1]
      new_bits = 9
    }
  ]
}

#-------------------------------
# Create Subnets
#-------------------------------
resource "aws_subnet" "main" {
  count                   = length(module.subnet_addrs.networks[*].cidr_block)
  vpc_id                  = data.aws_vpcs.main.ids[0]
  cidr_block              = module.subnet_addrs.networks[count.index].cidr_block
  availability_zone       = data.aws_availability_zones.main.names[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = format("%s-%s", var.subnet_nat_name, module.subnet_addrs.networks[count.index].name)
  }
}

resource "aws_subnet" "external" {
  count                   = length(var.subnet_gw_cidr)
  vpc_id                  = data.aws_vpcs.main.ids[0]
  cidr_block              = var.subnet_gw_cidr[count.index]
  availability_zone       = data.aws_availability_zones.main.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = format("%s-%s", var.subnet_gw_name, var.subnet_gw_cidr[count.index])
  }
}

#-------------------------------
# Create Internet Gateways
#-------------------------------
resource "aws_internet_gateway" "main" {
  vpc_id = data.aws_vpcs.main.ids[0]

  tags = {
    Name = "main"
  }
}

#-------------------------------
# Create NAT Gateways
#-------------------------------
resource "aws_nat_gateway" "main" {
  count             = length(module.subnet_addrs.networks[*].cidr_block)
  connectivity_type = "private"
  subnet_id         = data.aws_subnets.main.ids[count.index]
}
