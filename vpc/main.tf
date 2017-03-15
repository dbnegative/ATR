resource "aws_vpc" "vpc" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = "${var.vpc_options["enable_dns_hostnames"]}"
  enable_dns_support   = "${var.vpc_options["enable_dns_support"]}"

  tags {
    Name = "${var.vpc_name}"
  }
}

resource "aws_vpc_dhcp_options" "dns_search_path" {
  domain_name         = "priv.${var.hosted_zone_name}"
  domain_name_servers = ["${cidrhost(var.vpc_cidr, 2)}"]

  tags {
    Name       = "${var.vpc_name} - FQDN search"
    DomainName = "${var.hosted_zone_name}"
  }
}

resource "template_file" "ssh_keypair" {
  template = "${file(var.ssh_pubkey)}"
}

resource "aws_key_pair" "ssh_keypair" {
  key_name   = "${var.vpc_name}"
  public_key = "${template_file.ssh_keypair.rendered}"
}
