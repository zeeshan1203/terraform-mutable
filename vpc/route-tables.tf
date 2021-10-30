resource "aws_route_table" "private-rt" {
  depends_on                      = [aws_subnet.private, aws_vpc_peering_connection.peer-connection, aws_nat_gateway.nat]
  vpc_id                          = aws_vpc.main.id

  //  route {
  //    vpc_peering_connection_id     = aws_vpc_peering_connection.peer-connection.id
  //    cidr_block                    = var.DEFAULT_VPC_CIDR
  //  }
  //
  //  route {
  //    cidr_block                    = "0.0.0.0/0"
  //    nat_gateway_id                = aws_nat_gateway.nat.id
  //  }

  tags                            = {
    Name                          = "private-route-table"
  }
}

resource "aws_route_table" "public-rt" {
  depends_on                      = [aws_subnet.public, aws_vpc_peering_connection.peer-connection, aws_internet_gateway.igw]
  vpc_id                          = aws_vpc.main.id

  //  route {
  //    vpc_peering_connection_id     = aws_vpc_peering_connection.peer-connection.id
  //    cidr_block                    = var.DEFAULT_VPC_CIDR
  //  }
  //
  //  route {
  //    cidr_block                    = "0.0.0.0/0"
  //    gateway_id                    = aws_internet_gateway.igw.id
  //  }

  tags                            = {
    Name                          = "public-route-table"
  }
}

resource "aws_route" "route-in-default-vpc" {
  route_table_id                  = var.DEFAULT_VPC_ROUTE_TABLE
  destination_cidr_block          = var.VPC_CIDR
  vpc_peering_connection_id       = aws_vpc_peering_connection.peer-connection.id
}

resource "null_resource" "wait" {
  provisioner "local-exec" {
    command = "sleep 15"
  }
}

resource "aws_route_table_association" "public-association" {
  depends_on                      = [null_resource.wait]
  count                           = length(var.SUBNET_ZONES)
  subnet_id                       = element(aws_subnet.public.*.id,count.index)
  route_table_id                  = aws_route_table.public-rt.id
}

resource "aws_route_table_association" "private-association" {
  depends_on                      = [null_resource.wait]
  count                           = length(var.SUBNET_ZONES)
  subnet_id                       = element(aws_subnet.private.*.id,count.index)
  route_table_id                  = aws_route_table.private-rt.id
}
