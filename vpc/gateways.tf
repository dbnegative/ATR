resource "aws_nat_gateway" "public_gw" {
  allocation_id = "${element(aws_eip.gateways.*.id, count.index)}"
  subnet_id     = "${element(aws_subnet.public.*.id, count.index)}"
}

resource "aws_nat_gateway" "private_gw" {
  allocation_id = "${element(aws_eip.gateways.*.id, count.index)}"
  subnet_id     = "${element(aws_subnet.private.*.id, count.index)}"
}

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_eip" "gateways" {
  count = "${length(var.aws_azs)}"
  vpc   = true
}
