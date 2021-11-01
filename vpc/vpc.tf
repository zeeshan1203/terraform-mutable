resource "aws_vpc" "main" {
  cidr_block                  = var.VPC_CIDR
  instance_tenancy            = "default"

  tags = {
    Name                      = var.ENV
  }
}

resource "aws_subnet" "public" {
  count                       = length(var.SUBNET_ZONES)
  vpc_id                      = aws_vpc.main.id
  cidr_block                  = element(var.PUBLIC_SUBNETS_CIDR, count.index)
  availability_zone           = element(var.SUBNET_ZONES, count.index)

  tags = {
    Name                      = "public-subnet-${count.index + 1}"
  }
}

resource "aws_subnet" "private" {
  count                       = length(var.SUBNET_ZONES)
  vpc_id                      = aws_vpc.main.id
  cidr_block                  = element(var.PRIVATE_SUBNETS_CIDR, count.index)
  availability_zone           = element(var.SUBNET_ZONES, count.index)

  tags = {
    Name                      = "private-subnet-${count.index + 1}"
  }
}

