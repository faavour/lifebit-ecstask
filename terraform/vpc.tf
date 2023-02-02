resource "aws_vpc" "lifebit-vpc" {
  cidr_block = var.vpc_cider

  tags = {
    Name = "lifebit VPC"
  }
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.lifebit-vpc.id

  
}