variable "vpc_name" {
  description = "The name of the VPC to use"
  type        = list(string)
}

variable "region" {
  description = "The region to use"
  type        = string
  default     = "eu-west-1"
}

variable "vpc_cidrs" {
  description = "The CIDR block to use for the Main VPC"
  type        = list(string)
  default     = ["100.64.0.0/16", "100.100.100.0/24"]
}

variable "isolated_vpc_cidrs" {
  description = "The CIDR block to use for the Isolated VPC"
  type        = string
  default     = "100.65.0.0/24"
}

variable "vpc_isolated_name" {
  description = "The name of the isolated vpc to use"
  type        = string
}

variable "subnet_nat_name" {
  description = "The name of the nat subnet to use"
  type        = string
}

variable "subnet_isolated_name" {
  description = "The name of the first isolated subnet to use"
  type        = string
}

variable "subnets_spoke_names" {
  description = "The names of the spoke subnets"
  type        = list(string)
}

variable "subnet_gw_name" {
  description = "The name of the external subnet to use"
  type        = string
}

variable "subnet_gw_cidr" {
  description = "The CIDR block to use for the external subnet"
  type        = list(string)
  default     = ["100.100.100.0/25", "100.100.100.128/25"]
}

variable "igw_name" {
  description = "The name of the internet gateway to use"
  type        = string
  default     = "default-igw"
}

variable "private_nat_name" {
  description = "The name of the private nat to use"
  type        = string
  default     = "default-pnat"
}

variable "public_nat_name" {
  description = "The name of the public nat to use"
  type        = string
  default     = "default-enat"
}

variable "nateip_name" {
  description = "The name of the NAT Elastic IP to use"
  type        = string
  default     = "default-nateip"
}

variable "nat_route_name" {
  description = "The name of the NAT routes"
  type        = string
  default     = "default-natroute"
}

variable "igw_route_name" {
  description = "The name of the NAT routes"
  type        = string
  default     = "default-igwroute"
}
