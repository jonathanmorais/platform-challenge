resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = merge(
    var.additional_tags,
    {
      Name = "${var.name_prefix}-vpc"
    },
  )

}

resource "aws_internet_gateway" "internet_gw" {
  vpc_id = aws_vpc.vpc.id
  tags = merge(
    var.additional_tags,
    {
      Name = "${var.name_prefix}-internet-gw"
    },
  )
}

resource "aws_subnet" "public_subnets" {
  count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = element(var.availability_zones, count.index)
  cidr_block              = element(var.public_subnets_cidrs_per_availability_zone, count.index)
  map_public_ip_on_launch = true
  tags = merge(
    var.additional_tags,
    {
      Name = "${var.name_prefix}-public-net-${element(var.availability_zones, count.index)}"
    },
  )
}

resource "aws_eip" "nat_eip" {
  count = var.single_nat ? 1 : length(var.availability_zones)
  vpc   = true
  tags = merge(
    var.additional_tags,
    {
      Name = "${var.name_prefix}-nat-eip-${element(var.availability_zones, count.index)}"
    },
  )
}

resource "aws_nat_gateway" "nat_gw" {
  count         = var.single_nat ? 1 : length(var.availability_zones)
  allocation_id = var.single_nat ? aws_eip.nat_eip.0.id : element(aws_eip.nat_eip.*.id, count.index)
  subnet_id     = var.single_nat ? aws_subnet.public_subnets.0.id : element(aws_subnet.public_subnets.*.id, count.index)

  tags = merge(
    var.additional_tags,
    {
      Name = "${var.name_prefix}-nat-gw-${element(var.availability_zones, count.index)}"
    },
  )

  depends_on = [
    aws_internet_gateway.internet_gw
  ]
}

resource "aws_route_table" "public_subnets_route_table" {
  count  = length(var.availability_zones)
  vpc_id = aws_vpc.vpc.id
  tags = merge(
    var.additional_tags,
    {
      Name = "${var.name_prefix}-public-rt-${element(var.availability_zones, count.index)}"
    },
  )
}

resource "aws_route" "public_internet_route" {
  count = length(var.availability_zones)
  depends_on = [
    aws_internet_gateway.internet_gw,
    aws_route_table.public_subnets_route_table,
  ]
  route_table_id         = element(aws_route_table.public_subnets_route_table.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.internet_gw.id
}

resource "aws_route_table_association" "public_internet_route_table_associations" {
  count          = length(var.public_subnets_cidrs_per_availability_zone)
  subnet_id      = element(aws_subnet.public_subnets.*.id, count.index)
  route_table_id = element(aws_route_table.public_subnets_route_table.*.id, count.index)
}

resource "aws_subnet" "private_subnets" {
  count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = element(var.availability_zones, count.index)
  cidr_block              = element(var.private_subnets_cidrs_per_availability_zone, count.index)
  map_public_ip_on_launch = false
  tags = merge(
    var.additional_tags,
    {
      Name = "${var.name_prefix}-private-net-${element(var.availability_zones, count.index)}"
    },
  )
}

resource "aws_route_table" "private_subnets_route_table" {
  count  = length(var.availability_zones)
  vpc_id = aws_vpc.vpc.id
  tags = merge(
    var.additional_tags,
    {
      Name = "${var.name_prefix}-private-rt-${element(var.availability_zones, count.index)}"
    },
  )
}

resource "aws_route" "private_internet_route" {
  count = length(var.availability_zones)
  depends_on = [
    aws_internet_gateway.internet_gw,
    aws_route_table.private_subnets_route_table,
  ]
  route_table_id         = element(aws_route_table.private_subnets_route_table.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = var.single_nat ? aws_nat_gateway.nat_gw.0.id : element(aws_nat_gateway.nat_gw.*.id, count.index)
}

resource "aws_route_table_association" "private_internet_route_table_associations" {
  count     = length(var.private_subnets_cidrs_per_availability_zone)
  subnet_id = element(aws_subnet.private_subnets.*.id, count.index)
  route_table_id = element(
    aws_route_table.private_subnets_route_table.*.id,
    count.index,
  )
}
