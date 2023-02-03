variable "vpc_cider" {
    type = string
    description = "(The Cider block to use when setting up the VPC"
    default = "10.0.0.0/16"
}
variable "public_subnet_ciders" {
    type = list(string)
    description = "The subnet ciders for the public subnet"
    default = ["10.0.1.0/24", "10.0.2.0/24"]
}
variable "aws_azs" {
    type = list(string)
    description = "List of availability zones to deploy resources into"
    default = ["eu-west-2a", "eu-west-2b"]
}