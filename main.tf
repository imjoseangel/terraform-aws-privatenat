#-------------------------------
# Read VPC
#-------------------------------

data "aws_vpcs" "main" {}

data "aws_vpc" "main" {
  count = length(data.aws_vpcs.main.ids)
  id    = tolist(data.aws_vpcs.main.ids)[count.index]
}

data "aws_subnets" "main" {
  filter {
    name   = "tag:Name"
    values = var.subnets_spoke_names
  }
}

data "aws_availability_zones" "main" {
  state = "available"
}

#-------------------------------
# Create Secondary CIDR
#-------------------------------
resource "aws_vpc_ipv4_cidr_block_association" "main" {
  count      = length(var.vpc_cidrs)
  vpc_id     = data.aws_vpc.main[0].id
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
  vpc_id                  = data.aws_vpc.main[0].id
  cidr_block              = module.subnet_addrs.networks[count.index].cidr_block
  availability_zone       = data.aws_availability_zones.main.names[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = format("%s-%s", var.subnet_nat_name, module.subnet_addrs.networks[count.index].name)
  }
}

resource "aws_subnet" "external" {
  count                   = length(var.subnet_gw_cidr)
  vpc_id                  = data.aws_vpc.main[0].id
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
  vpc_id = data.aws_vpc.main[0].id

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
  vpc_id = data.aws_vpc.main[0].id
  route {
    cidr_block     = "10.0.0.0/8"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  route {
    cidr_block     = "172.16.0.0/12"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  # route {
  #   cidr_block         = "100.65.0.0/16"
  #   transit_gateway_id = aws_ec2_transit_gateway.main.id
  # }

  route {
    cidr_block     = "192.168.0.0/16"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  dynamic "route" {
    for_each = aws_nat_gateway.external == null ? 0 : length(aws_nat_gateway.external)
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.external[count.index].id
    }
  }

  tags = {
    Name = format("%sroute-%s", var.subnet_nat_name, data.aws_availability_zones.main.names[count.index])
  }
}

resource "aws_route_table_association" "main" {
  count          = length(aws_subnet.main)
  subnet_id      = aws_subnet.main[count.index].id
  route_table_id = aws_route_table.main[count.index].id
}

resource "aws_route_table" "external" {
  count  = length(aws_subnet.external)
  vpc_id = data.aws_vpc.main[0].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  # route {
  #   cidr_block         = "100.65.0.0/16"
  #   transit_gateway_id = aws_ec2_transit_gateway.main.id
  # }

  tags = {
    Name = format("%sroute-%s", var.igw_name, data.aws_availability_zones.main.names[count.index])
  }
}

resource "aws_route_table_association" "external" {
  count          = length(aws_subnet.external)
  subnet_id      = aws_subnet.external[count.index].id
  route_table_id = aws_route_table.external[count.index].id
}

# #-------------------------------
# # Isolated VPC
# #-------------------------------

# resource "aws_vpc" "isolated" {
#   cidr_block           = var.isolated_vpc_cidr
#   enable_dns_hostnames = true

#   tags = {
#     Name = var.vpc_isolated_name
#   }
# }

# #-------------------------------
# # Calculate Isolated Subnets
# #-------------------------------
# module "subnet_addrs_isolated" {
#   source  = "hashicorp/subnets/cidr"
#   version = "1.0.0"

#   base_cidr_block = var.isolated_vpc_cidr

#   networks = [
#     {
#       name     = data.aws_availability_zones.main.names[0]
#       new_bits = 1
#     },
#     {
#       name     = data.aws_availability_zones.main.names[1]
#       new_bits = 1
#     }
#   ]
# }

# #-------------------------------
# # Create Isolated Subnets
# #-------------------------------
# resource "aws_subnet" "isolated" {
#   count                   = length(module.subnet_addrs_isolated.networks[*].cidr_block)
#   vpc_id                  = aws_vpc.isolated.id
#   cidr_block              = module.subnet_addrs_isolated.networks[count.index].cidr_block
#   availability_zone       = data.aws_availability_zones.main.names[count.index]
#   map_public_ip_on_launch = false

#   tags = {
#     Name = format("%s-%s", var.subnet_isolated_name, module.subnet_addrs_isolated.networks[count.index].name)
#   }
# }

# #-------------------------------
# # Create Transit Gateway
# #-------------------------------

# resource "aws_ec2_transit_gateway" "main" {

#   description                    = "Transit gateway for Isolated-Spoke VPC"
#   auto_accept_shared_attachments = "enable"
#   tags = {
#     Name = var.transit_gateway_name
#   }
# }

# resource "aws_ec2_transit_gateway_vpc_attachment" "main" {
#   transit_gateway_id = aws_ec2_transit_gateway.main.id
#   vpc_id             = data.aws_vpc.main[0].id
#   subnet_ids         = aws_subnet.main[*].id
#   tags = {
#     Name = format("%s-tgw-attachment", var.vpc_name[0])
#   }
# }

# resource "aws_ec2_transit_gateway_vpc_attachment" "isolated" {
#   transit_gateway_id = aws_ec2_transit_gateway.main.id
#   vpc_id             = aws_vpc.isolated.id
#   subnet_ids         = aws_subnet.isolated[*].id
#   tags = {
#     Name = format("%s-tgw-attachment", var.vpc_isolated_name)
#   }
# }

# resource "aws_ec2_transit_gateway_route" "main" {
#   destination_cidr_block         = "0.0.0.0/0"
#   transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.main.id
#   transit_gateway_route_table_id = aws_ec2_transit_gateway.main.association_default_route_table_id
# }

# #-------------------------------
# # Create Isolated Routes
# #-------------------------------

# resource "aws_route_table" "isolated" {
#   vpc_id = aws_vpc.isolated.id

#   route {
#     cidr_block         = "0.0.0.0/0"
#     transit_gateway_id = aws_ec2_transit_gateway.main.id
#   }

#   tags = {
#     Name = var.subnet_isolated_name
#   }
# }

# resource "aws_route_table_association" "isolated" {
#   count          = length(aws_subnet.isolated)
#   subnet_id      = aws_subnet.isolated[count.index].id
#   route_table_id = aws_route_table.isolated.id
# }
