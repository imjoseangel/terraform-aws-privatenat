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
  description = "The CIDR block to use for the VPC"
  type        = list(string)
  default     = ["100.64.0.0/16", "100.100.100.0/24"]
}

variable "subnet_nat_name" {
  description = "The name of the nat subnet to use"
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
