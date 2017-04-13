output "rds_endpoint" {
  value = "${aws_db_instance.rancher_rds.endpoint.address}"
}

output "elb_cert_pem" {
  value = "${acme_certificate.certificate.certificate_pem}"
}

output "elb_private_key_pem" {
  value = "${acme_certificate.certificate.private_key_pem}"
}
