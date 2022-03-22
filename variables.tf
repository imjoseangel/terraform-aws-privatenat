variable "vpc_name" {
  description = "The name of the VPC to use"
  type        = list(string)
  default     = []
}

variable "region" {
  description = "The region to use"
  type        = string
  default     = "eu-west-1"
}

variable "vpc_cidr" {
  description = "The CIDR block to use for the VPC"
  type        = string
  default     = "100.64.0.0/16"
}

variable "subnet_name" {
  description = "The name of the subnet to use"
  type        = string
  default     = null
}
