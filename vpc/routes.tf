resource "aws_route_table" "public_routing_table" {
  count = "${length(var.aws_azs)}"

  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    AvailabilityZone = "${var.aws_region}${element(var.aws_azs, count.index)}"
    Name             = "${var.vpc_name} public ${var.aws_region}${element(var.aws_azs, count.index)}"
  }
}

resource "aws_route_table_association" "public_route_association" {
  count = "${length(var.aws_azs)}"

  route_table_id = "${element(aws_route_table.public_routing_table.*.id, count.index)}"
  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
}

resource "aws_route" "public_internet_default_gateway" {
  count = "${length(var.aws_azs)}"

  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.gateway.id}"
  route_table_id         = "${element(aws_route_table.public_routing_table.*.id, count.index)}"
}

resource "aws_route_table" "private_routing_table" {
  count = "${length(var.aws_azs)}"

  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    AvailabilityZone = "${var.aws_region}${element(var.aws_azs, count.index)}"
    Name             = "${var.vpc_name} private ${var.aws_region}${element(var.aws_azs, count.index)}"
  }
}

resource "aws_route_table_association" "private_route_association" {
  count = "${length(var.aws_azs)}"

  route_table_id = "${element(aws_route_table.private_routing_table.*.id, count.index)}"
  subnet_id      = "${element(aws_subnet.private.*.id, count.index)}"
}

resource "aws_route" "private_internet_default_gateway" {
  count = "${length(var.aws_azs)}"

  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${element(aws_nat_gateway.private_gw.*.id, count.index)}"
  route_table_id         = "${element(aws_route_table.private_routing_table.*.id, count.index)}"
}
