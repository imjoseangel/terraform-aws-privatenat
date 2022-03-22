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
    values = var.subnets_spoke
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

output "output" {
  value = module.subnet_addrs.networks[*].cidr_block
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
    Name = format("%s-%s", var.subnet_name, module.subnet_addrs.networks[count.index].name)
  }
}

#-------------------------------
# Create Private NAT Gateway
#-------------------------------
resource "aws_nat_gateway" "main" {
  count             = length(module.subnet_addrs.networks[*].cidr_block)
  connectivity_type = "private"
  subnet_id         = data.aws_subnets.main.ids[count.index]
}
