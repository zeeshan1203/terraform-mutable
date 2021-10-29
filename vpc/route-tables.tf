resource "aws_route_table" "private-rt" {
  vpc_id          = aws_vpc.main.id

  tags            = {
    Name          = "private-route-table"
  }
}

resource "aws_route_table" "public-rt" {
  vpc_id          = aws_vpc.main.id

  tags            = {
    Name          = "public-route-table"
  }
}
