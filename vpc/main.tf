resource "aws_vpc" "vpc" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = "${var.vpc_options["enable_dns_hostnames"]}"
  enable_dns_support   = "${var.vpc_options["enable_dns_support"]}"

  tags {
    Name = "${var.aws_vpc_name}"
  }
}
