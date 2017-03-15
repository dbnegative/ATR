resource "aws_subnet" "public" {
  count = "${length(var.aws_azs)}"

  vpc_id            = "${aws_vpc.vpc.id}"
  availability_zone = "${var.aws_region}${element(var.aws_azs, count.index)}"
  cidr_block        = "${cidrsubnet(var.vpc_cidr, 7, count.index+4)}"

  tags {
    Name = "public-${var.aws_region}"
    AZ   = "${var.aws_region}${element(var.aws_azs, count.index)}"
  }
}

resource "aws_subnet" "private" {
  count = "${length(var.aws_azs)}"

  vpc_id            = "${aws_vpc.vpc.id}"
  availability_zone = "${var.aws_region}${element(var.aws_azs, count.index)}"
  cidr_block        = "${cidrsubnet(var.vpc_cidr, 7, count.index)}"

  tags {
    Name = "private-${var.aws_region}"
    AZ   = "${var.aws_region}${element(var.aws_azs, count.index)}"
  }
}
