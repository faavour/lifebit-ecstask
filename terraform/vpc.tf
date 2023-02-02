resource "aws_vpc" "lifebit-vpc" {
  cidr_block = var.vpc_cider

  tags = {
    Name = "lifebit VPC"
  }
}