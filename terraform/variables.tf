variable "vpc_cider" {
    type = string
    description = "(The Cider block to use when setting up the VPC"
    default = "10.0.0.0/16"
}
variable "public_subnet_ciders" {
    type = list(string)
    