resource "aws_vpc" "lifebit-vpc" {
  cidr_block = var.vpc_cider

  tags = {
    Name = "lifebit VPC"
  }
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.lifebit-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Lifebit RT"
  }
}