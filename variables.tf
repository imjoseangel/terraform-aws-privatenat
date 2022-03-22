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
