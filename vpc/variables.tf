variable "aws_region" {
  description = "AWS EC2 Region for VPC"
}

variable "vpc_name" {
  description = "AWS VPC Name"
}

variable "vpc_cidr" {
  description = "VPC CIDR"
}

variable "vpc_options" {
  type = "map"

  default = {
    enable_dns_hostnames = "true"
    enable_dns_support   = "true"
  }
}

variable "aws_azs" {
  type = "list"

  default = [
    #"a",
    "b",

    "c",
  ]
}

variable "hosted_zone_name" {
  type        = "string"
  description = "Name of hosted zone"
}

variable "ssh_pubkey" {
  type        = "string"
  description = "Path to the SSH public key"
}
