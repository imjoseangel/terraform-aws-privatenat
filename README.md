# terraform-aws-privatenat

[![Terraform](https://github.com/imjoseangel/terraform-aws-privatenat/actions/workflows/terraform.yml/badge.svg)](https://github.com/imjoseangel/terraform-aws-privatenat/actions/workflows/terraform.yml)

## Deploy a Terraform Private NAT Subnet

This Terraform module deploys a Private NAT in Amazon Web Services.

### NOTES

* Assumes only two private subnets are available in the VPC.

## Usage in Terraform 1.0

```terraform
module "privatenat" {
  source              = "github.com/imjoseangel/terraform-aws-privatenat"
  vpc_name            = ["my-vpc"]
  subnet_nat_name     = "my-subnet-nat"
  subnet_gw_name      = "my-subnet-gw"
  subnets_spoke_names = ["spoke-eu-west-1a", "spoke-eu-west-1b"]
  igw_name            = "my-igw"
  private_nat_name    = "my-private-nat"
  nateip_name         = "my-nateip"
  nat_route_name      = "my-nat-route"
  igw_route_name      = "my-igw-route"
}
```

## Authors

Originally created by [imjoseangel](http://github.com/imjoseangel)

## License

[MIT](LICENSE)
