output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "vpc_cidr_block" {
  value = aws_vpc.vpc.cidr_block
}

output "availability_zones" {
  value = var.availability_zones
}

output "internet_gateway_id" {
  value = aws_internet_gateway.internet_gw.id
}

output "public_subnets_ids" {
  value = aws_subnet.public_subnets.*.id
}

output "public_subnets_route_table_id" {
  value = aws_route_table.public_subnets_route_table.*.id
}

output "nat_gw_ids" {
  value = aws_nat_gateway.nat_gw.*.id
}

output "private_subnets_ids" {
  value = aws_subnet.private_subnets.*.id
}

output "private_subnets_route_table_id" {
  value = aws_route_table.private_subnets_route_table.*.id
}
