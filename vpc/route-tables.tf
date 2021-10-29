resource "aws_route_table" "private-rt" {
  vpc_id          = aws_vpc.main.id

  route {
    vpc_peering_connection_id     = aws_vpc_peering_connection.peer-connection.id
    cidr_block                    = var.DEFAULT_VPC_CIDR
  }

  tags            = {
    Name          = "private-route-table"
  }
}

resource "aws_route_table" "public-rt" {
  vpc_id          = aws_vpc.main.id

  route {
    vpc_peering_connection_id     = aws_vpc_peering_connection.peer-connection.id
    cidr_block                    = var.DEFAULT_VPC_CIDR
  }

  tags            = {
    Name          = "public-route-table"
  }
}

resource "aws_route" "route-in-default-vpc" {
  route_table_id            = var.DEFAULT_VPC_ROUTE_TABLE
  destination_cidr_block    = var.VPC_CIDR
  vpc_peering_connection_id = aws_vpc_peering_connection.peer-connection.id
}