#-------------------------------
# Read VPC
#-------------------------------

data "aws_vpcs" "main" {
  filter {
    name   = "tag:Name"
    values = var.vpc_name
  }
}

#-------------------------------
# Create Subnets
#-------------------------------
