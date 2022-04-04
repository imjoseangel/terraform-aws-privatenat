output "vpc_id" {
  value = data.aws_vpcs.main.ids[0]
}

output "availability_zones" {
  value = data.aws_availability_zones.main.names
}

output "route_table" {
  value = aws_route_table.main
}
