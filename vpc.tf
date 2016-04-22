resource "aws_vpc" "default" {
    cidr_block = "${var.vpc_cidr}"
     enable_dns_hostnames = "${var.vpc_options.enable_dns_hostnames}"
     enable_dns_support = "${var.vpc_options.enable_dns_support}"
    tags {
        Name = "terraform_vpc"
    }
}

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_subnet" "public" {
    vpc_id = "${aws_vpc.default.id}"
    cidr_block = "${var.vpc_subnets.public}"
    availability_zone = "${var.aws_region}a"
    tags {
        Name = "Public-${var.aws_region}"
    }
}

resource "aws_subnet" "private" {
    vpc_id = "${aws_vpc.default.id}"
    cidr_block = "${var.vpc_subnets.private}"
    availability_zone = "${var.aws_region}c"

    tags {
        Name = "Private-${var.aws_region}$"
    }
}

resource "aws_eip" "public" {
    vpc = true
}

resource "aws_eip" "private" {
    vpc = true
}

resource "aws_nat_gateway" "public_gw" {
    allocation_id = "${aws_eip.public.id}"
    subnet_id = "${aws_subnet.public.id}"
}

resource "aws_nat_gateway" "private_gw" {
    allocation_id = "${aws_eip.private.id}"
    subnet_id = "${aws_subnet.private.id}"
}
