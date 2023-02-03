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

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.lifebit-vpc.id
  tags = {
    Name = "Lifebit GW"
  }
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.lifebit-vpc.id
  cidr_block              = element(var.public_subnet_ciders, count.index)
  availability_zone       = element(var.aws_azs, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "Lifebit-Public-Subnet-${count.index + 1}"
  }
}

resource "aws_route_table_association" "rta" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.rt.id
}

resource "aws_security_group" "http_traffic" {
  name        = "allow_http"
  description = "Allow http traffic"