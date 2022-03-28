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
  count      = length(var.vpc_cidrs)
  vpc_id     = data.aws_vpcs.main.ids[0]
  cidr_block = var.vpc_cidrs[count.index]
}

#-------------------------------
# Calculate Subnets
#-------------------------------
module "subnet_addrs" {
  source  = "hashicorp/subnets/cidr"
  version = "1.0.0"

  base_cidr_block = aws_vpc_ipv4_cidr_block_association.main[0].cidr_block

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
    Name = format("%s-%s", var.subnet_gw_name, data.aws_availability_zones.main.names[count.index])
  }

  depends_on = [
    aws_internet_gateway.main
  ]
}

#-------------------------------
# Create Internet Gateways
#-------------------------------
resource "aws_internet_gateway" "main" {
  vpc_id = data.aws_vpcs.main.ids[0]

  tags = {
    Name = var.igw_name
  }
}

#-------------------------------
# Create NAT Gateways
#-------------------------------
resource "aws_nat_gateway" "main" {
  count             = length(aws_subnet.main)
  connectivity_type = "private"
  subnet_id         = data.aws_subnets.main.ids[count.index]
  tags = {
    Name = format("%s-%s", var.private_nat_name, data.aws_availability_zones.main.names[count.index])
  }
}

resource "aws_eip" "main" {
  count = length(var.subnet_gw_cidr)
  vpc   = true
  depends_on = [
    aws_internet_gateway.main
  ]

  tags = {
    Name = format("%s-%02d", var.nateip_name, count.index + 1)
  }
}

resource "aws_nat_gateway" "external" {
  count             = length(aws_subnet.external)
  connectivity_type = "public"
  allocation_id     = aws_eip.main[count.index].id
  subnet_id         = aws_subnet.external[count.index].id

  depends_on = [
    aws_internet_gateway.main, aws_eip.main
  ]

  tags = {
    Name = format("%s-%s", var.public_nat_name, data.aws_availability_zones.main.names[count.index])
  }
}

#-------------------------------
# Create Routes
#-------------------------------

resource "aws_route_table" "main" {
  count  = length(aws_subnet.main)
  vpc_id = data.aws_vpcs.main.ids[0]
  route {
    cidr_block     = "10.0.0.0/8"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  route {
    cidr_block     = "172.16.0.0/12"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  route {
    cidr_block     = "192.168.0.0/16"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.external[count.index].id
  }

  tags = {
    Name = format("%s-%s", var.nat_route_name, data.aws_availability_zones.main.names[count.index])
  }
}

resource "aws_route_table_association" "main" {
  count          = length(aws_subnet.main)
  subnet_id      = aws_subnet.main[count.index].id
  route_table_id = aws_route_table.main[count.index].id
}

resource "aws_route_table" "external" {
  count  = length(aws_subnet.external)
  vpc_id = data.aws_vpcs.main.ids[0]

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = format("%s-%s", var.igw_route_name, data.aws_availability_zones.main.names[count.index])
  }
}

resource "aws_route_table_association" "external" {
  count          = length(aws_subnet.external)
  subnet_id      = aws_subnet.external[count.index].id
  route_table_id = aws_route_table.external[count.index].id
}

#-------------------------------
# Isolated VPC
#-------------------------------

resource "aws_vpc" "isolated" {
  cidr_block           = var.isolated_vpc_cidrs
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc_isolated_name
  }
}

#-------------------------------
# Calculate Isolated Subnets
#-------------------------------
module "subnet_addrs_isolated" {
  source  = "hashicorp/subnets/cidr"
  version = "1.0.0"

  base_cidr_block = var.isolated_vpc_cidrs

  networks = [
    {
      name     = data.aws_availability_zones.main.names[0]
      new_bits = 8
    },
    {
      name     = data.aws_availability_zones.main.names[1]
      new_bits = 8
    }
  ]
}

#-------------------------------
# Create Isolated Subnets
#-------------------------------
resource "aws_subnet" "main" {
  count                   = length(module.subnet_addrs_isolated.networks[*].cidr_block)
  vpc_id                  = aws_vpcs.isolated.id
  cidr_block              = module.subnet_addrs_isolated.networks[count.index].cidr_block
  availability_zone       = data.aws_availability_zones.main.names[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = format("%s-%s", var.subnet_isolated_name, module.subnet_addrs_isolated.networks[count.index].name)
  }
}
