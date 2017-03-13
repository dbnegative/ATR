variable "aws_region" {
  description = "AWS EC2 Region for VPC"
}

variable "aws_vpc_name" {
  description = "AWS VPC Name"
}

variable "vpc_cidr" {
  description = "VPC CIDR"
}

variable "vpc_options" {
  type = "map"

  default = {
    enable_dns_hostnames = "true"
    enable_dns_support   = "false"
  }
}

variable "aws_azs" {
  type = "list"

  default = [
    "a",
    "b",
    "c",
  ]
}
