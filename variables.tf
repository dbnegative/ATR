variable "aws_region" {
  description = "AWS EC2 Region for VPC"
  default = "eu-west-1"
}
variable "vpc_cidr" {
  description = "VPC CIDR"
  default = "10.0.0.0/16"
}

variable "vpc_options" {
  type = "map"
  default = {
    enable_dns_hostnames = "true"
    enable_dns_support = "false"
  }
}

variable "vpc_subnets" {
  default = {
    public = "10.0.1.0/24"
    private = "10.0.2.0/24"
  }
}
