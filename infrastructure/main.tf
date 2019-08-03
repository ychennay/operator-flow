provider "aws" {
  region = var.provider_region
}


resource "aws_vpc" "operator_flow_vpc" {
  cidr_block = var.vpc_cidr_block
  enable_dns_hostnames = true
  tags = {
    Name = "operator_flow_vpc"
  }
}

resource "aws_subnet" "operator_flow_public_subnet" {
  cidr_block = var.public_subnet_cidr_block
  vpc_id = aws_vpc.operator_flow_vpc.id
  map_public_ip_on_launch = true

  tags = {
    Name = "operator_flow_public_subnet"
  }
}

data "aws_subnet" "operator_flow_public_subnet_id" {
  filter {
    name = "tag:Name"
    values = [
      "operator_flow_public_subnet"]
  }
}

resource "aws_subnet" "operator_flow_private_subnet" {
  cidr_block = var.private_subnet_cidr_block
  vpc_id = aws_vpc.operator_flow_vpc.id
  map_public_ip_on_launch = false
  tags = {
    Name = "operator_flow_private_subnet"
  }
}

resource "aws_internet_gateway" "operator_flow_vpc_igw" {
  vpc_id = aws_vpc.operator_flow_vpc.id

  tags = {
    Name = "operator_flow_igw"
  }
}

data "aws_route_table" "operator_flow_vpc_route_table" {
  vpc_id = aws_vpc.operator_flow_vpc.id
}

resource "aws_route" "internet_egress_route" {
  route_table_id = data.aws_route_table.operator_flow_vpc_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.operator_flow_vpc_igw.id
  depends_on = [
    "aws_internet_gateway.operator_flow_vpc_igw"]
}