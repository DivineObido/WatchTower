resource "aws_vpc" "watchtower" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "watch Tower Vpc"
    Environment = "Dev"
  }
}

resource "aws_subnet" "watchtower_subnet" {
  for_each = local.subnets
  vpc_id = aws_vpc.watchtower.id
  cidr_block = each.value.cidr_block
  availability_zone = each.value.availabity_zones
  map_public_ip_on_launch = each.value.is_public

  tags = {
    Name = "watchTower ${each.key} subnet"
    Environment = "Dev"
  }
}

resource "aws_internet_gateway" "watchtower_IG" {
  vpc_id = aws_vpc.watchtower.id
}

resource "aws_route_table" "watchtower_RT" {
  vpc_id = aws_vpc.watchtower.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.watchtower_IG.id
  }
}

resource "aws_route_table_association" "RT_association" {
  route_table_id = aws_route_table.watchtower_RT.id
  for_each = {for key, subnet in aws_subnet.watchtower_subnet : key => subnet if local.subnets[key].is_public}
  subnet_id = each.value.id
}