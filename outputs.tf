output "vpc_id" {
  value = data.aws_vpcs.main.ids[0]
}

output "availability_zones" {
  value = data.aws_availability_zones.main.ids
}
