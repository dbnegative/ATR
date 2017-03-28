output "rds_endpoint" {
  value = "${aws_db_instance.rancher_rds.endpoint.address}"
}
