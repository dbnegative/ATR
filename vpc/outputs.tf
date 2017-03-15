output "vpc_id" {
  value = "${aws_vpc.vpc.id}"
}

output "private_subnets" {
  value = "${split(",",join(",", aws_subnet.private.*.id))}"
}

output "public_subnets" {
  value = "${split(",",join(",", aws_subnet.public.*.id))}"
}

output "cidr_block" {
  value = "${aws_vpc.vpc.cidr_block}"
}
