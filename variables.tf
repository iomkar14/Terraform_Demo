variable "aws_region" {}
data "aws_availability_zones" "available" {}
variable "vpc_cidr" {}
variable "cidrs" {
  type = map
}
variable "localip" {}

variable "dev_instance_type" {}
variable "dev_ami" {}
variable "public_key_path" {}
variable "key_name" {}