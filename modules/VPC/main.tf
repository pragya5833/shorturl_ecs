resource "aws_vpc" "main" {
  cidr_block = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support = true
}
resource "aws_subnet" "public_subnet" {
  count = length(var.supported_azs)
  availability_zone = element(var.supported_azs,count.index)
  cidr_block = cidrsubnet(aws_vpc.main.cidr_block,8,count.index+1)
  vpc_id = aws_vpc.main.id
  map_public_ip_on_launch = true
}
resource "aws_subnet" "private_subnet" {
  count = length(var.supported_azs)
  availability_zone = element(var.supported_azs,count.index)
  cidr_block = cidrsubnet(aws_vpc.main.cidr_block,8,count.index+length(var.supported_azs)+1)
  vpc_id = aws_vpc.main.id
}
resource "aws_internet_gateway" "main_internet_gateway" {
  vpc_id = aws_vpc.main.id
}
resource "aws_eip" "nat_eips" {
  count = length(var.supported_azs)
}
resource "aws_nat_gateway" "nat_gateway_public" {
  count = length(var.supported_azs)
  subnet_id = element(aws_subnet.public_subnet.*.id,count.index)
  allocation_id = element(aws_eip.nat_eips.*.id,count.index)
}
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_internet_gateway.id
  }
}
resource "aws_route_table" "private_route_table" {
count = length(var.supported_azs)
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.nat_gateway_public.*.id,count.index)   
  }
}
resource "aws_route_table_association" "public_association" {
    count = length(var.supported_azs)
  route_table_id = aws_route_table.public_route_table.id
  subnet_id = element(aws_subnet.public_subnet.*.id,count.index)
}
resource "aws_route_table_association" "private_association" {
  count=length(var.supported_azs)
  route_table_id = element(aws_route_table.private_route_table.*.id,count.index)
  subnet_id = element(aws_subnet.private_subnet.*.id,count.index)
}
resource "aws_network_acl" "public_nacl" {
  vpc_id = aws_vpc.main.id
  dynamic "ingress" {
    for_each = [for rule in var.public_nacl:rule if !rule.egress]
    content {
      rule_no = ingress.value.rule_number
      from_port = ingress.value.from_port
      to_port = ingress.value.to_port
      protocol = ingress.value.protocol
      cidr_block = ingress.value.cidr_block
      action = ingress.value.action
    }
  }
  dynamic "egress" {
    for_each = [for rule in var.public_nacl:rule if rule.egress]
    content {
     rule_no = egress.value.rule_number
      from_port = egress.value.from_port
      to_port = egress.value.to_port
      protocol = egress.value.protocol
      cidr_block = egress.value.cidr_block
      action = egress.value.action 
    }
  }
}
resource "aws_network_acl" "private_nacl" {
  vpc_id = aws_vpc.main.id
  dynamic "ingress" {
    for_each = [for rule in var.private_nacl_rules:rule if !rule.egress]
    content {
      rule_no = ingress.value.rule_number
      from_port = ingress.value.from_port
      to_port = ingress.value.to_port
      protocol = ingress.value.protocol
      cidr_block = ingress.value.cidr_block
      action = ingress.value.action
    }
  }
  dynamic "egress" {
    for_each = [for rule in var.private_nacl_rules:rule if rule.egress]
    content {
     rule_no = egress.value.rule_number
      from_port = egress.value.from_port
      to_port = egress.value.to_port
      protocol = egress.value.protocol
      cidr_block = egress.value.cidr_block
      action = egress.value.action 
    }
  }
}
resource "aws_network_acl_association" "public_nacl_association" {
  for_each = {for idx,id in local.public_subnet_ids: idx=>id}
  network_acl_id = aws_network_acl.public_nacl.id
  subnet_id = each.value
}
resource "aws_network_acl_association" "private_nacl_association" {
    for_each = {for idx,id in local.private_subnet_ids: idx=>id}
  network_acl_id = aws_network_acl.private_nacl.id
  subnet_id = each.value
}