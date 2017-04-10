# Create rancher aliased A record to rancher mgmt elb
resource "aws_route53_record" "rancher_mgmt_elb_dns" {
  zone_id = "${var.hosted_zone_id}"
  name    = "ranchermgmt.${var.domain}"
  type    = "A"

  alias {
    name                   = "${aws_elb.rancher_mgmt_elb.dns_name}"
    zone_id                = "${aws_elb.rancher_mgmt_elb.zone_id}"
    evaluate_target_health = true
  }
}

# Create rancher aliased A record to rancher mgmt elb
resource "aws_route53_record" "rancher_mgmt_elb_dns_alt" {
  zone_id = "${var.hosted_zone_id}"
  name    = "ranchermgmt2.${var.domain}"
  type    = "A"

  alias {
    name                   = "${aws_elb.rancher_mgmt_elb.dns_name}"
    zone_id                = "${aws_elb.rancher_mgmt_elb.zone_id}"
    evaluate_target_health = true
  }
}

# Create the private key for the registration (not the certificate)
resource "tls_private_key" "private_key" {
  algorithm = "RSA"
}

# Set up a registration using a private key from tls_private_key
resource "acme_registration" "reg" {
  server_url      = "https://acme-staging.api.letsencrypt.org/directory"
  account_key_pem = "${tls_private_key.private_key.private_key_pem}"
  email_address   = "${var.domain_email_address}"
}

# Create a certificate
resource "acme_certificate" "certificate" {
  server_url                = "https://acme-staging.api.letsencrypt.org/directory"
  account_key_pem           = "${tls_private_key.private_key.private_key_pem}"
  common_name               = "ranchermgmt.${var.domain}"
  subject_alternative_names = ["ranchermgmt2.${var.domain}"]

  dns_challenge {
    provider = "route53"
  }

  registration_url = "${acme_registration.reg.id}"
}

# Upload Lets Encrypt cert to AWS
resource "aws_iam_server_certificate" "rancher_mgmt_cert" {
  name_prefix      = "rancher-mgmt-cert"
  certificate_body = "${acme_certificate.certificate.certificate_pem}"
  private_key      = "${acme_certificate.certificate.private_key_pem}"

  lifecycle {
    create_before_destroy = true
  }
}

# Create elb to load balance between rancher management instances
resource "aws_elb" "rancher_mgmt_elb" {
  name            = "rancher-mangement-elb"
  subnets         = ["${var.public_subnets}"]
  security_groups = ["${aws_security_group.rancher_mgamt_elb_sec_group.id}"]

  listener {
    instance_port      = 8080
    instance_protocol  = "tcp"
    lb_port            = 443
    lb_protocol        = "ssl"
    ssl_certificate_id = "${aws_iam_server_certificate.rancher_mgmt_cert.arn}"
  }

  health_check {
    healthy_threshold   = 10
    unhealthy_threshold = 10
    timeout             = 3
    target              = "tcp:8080"
    interval            = 30
  }

  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags {
    Name = "rancher management elb"
  }
}

# Create Load balancer policy to enable proxy support
resource "aws_load_balancer_policy" "rancher_proxy_policy" {
  load_balancer_name = "${aws_elb.rancher_mgmt_elb.name}"
  policy_name        = "rancher-proxy-policy"
  policy_type_name   = "ProxyProtocolPolicyType"

  policy_attribute = {
    name  = "ProxyProtocol"
    value = "true"
  }
}

# Apply proxy policy to load balancer
resource "aws_load_balancer_backend_server_policy" "rancher_mgmt_elb_backend_auth_policies_443" {
  load_balancer_name = "${aws_elb.rancher_mgmt_elb.name}"
  instance_port      = 443

  policy_names = [
    "${aws_load_balancer_policy.rancher_proxy_policy.policy_name}",
  ]
}

# Apply proxy policy to load balancer
resource "aws_load_balancer_backend_server_policy" "rancher_mgmt_elb_backend_auth_policies_8080" {
  load_balancer_name = "${aws_elb.rancher_mgmt_elb.name}"
  instance_port      = 8080

  policy_names = [
    "${aws_load_balancer_policy.rancher_proxy_policy.policy_name}",
  ]
}

# Create security group to allow access to elb SSL port
resource "aws_security_group" "rancher_mgamt_elb_sec_group" {
  name        = "rancher managment elb SG"
  description = "rancher managment elb security group"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = ["10.0.0.0/8"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name            = "rancher mgmt"
    EnvironmentName = "${var.vpc_name}"
    Type            = "ELB"
  }
}

# Create rancher management instances ASG 
resource "aws_autoscaling_group" "rancher_mgmt_asg" {
  name = "Rancher mgmt ASG"

  desired_capacity = "${var.cluster_size}"
  max_size         = "${var.cluster_size}"
  min_size         = "${var.cluster_size}"

  launch_configuration = "${aws_launch_configuration.rancher_mgmt_launch_config.name}"
  termination_policies = ["OldestInstance"]
  vpc_zone_identifier  = ["${var.private_subnets}"]

  load_balancers = ["${aws_elb.rancher_mgmt_elb.name}"]

  health_check_grace_period = 300
  health_check_type         = "ELB"

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances",
  ]

  tag {
    key                 = "Name"
    value               = "Rancher mgmt ASG"
    propagate_at_launch = true
  }

  tag {
    key                 = "EnvironmentName"
    value               = "${var.vpc_name}"
    propagate_at_launch = true
  }
}

# Create template file for userdata to register management instances on boot
data "template_file" "mgmt_userdata" {
  template = "${file("${path.module}/userdata.yml.tpl")}"

  vars {
    username = "${var.root_dbusername}"
    password = "${var.root_dbpassword}"
    port     = "${aws_db_instance.rancher_rds.port}"
    endpoint = "${element(split(":",aws_db_instance.rancher_rds.endpoint),0)}"
    dbname   = "${var.dbname}"
  }
}

# Create rancher management instance launch config with userdata
resource "aws_launch_configuration" "rancher_mgmt_launch_config" {
  lifecycle {
    create_before_destroy = true
  }

  name_prefix = "rancher-mgmt-"

  image_id      = "${var.image_id}"
  instance_type = "t2.medium"
  key_name      = "${var.vpc_name}"

  iam_instance_profile = "${aws_iam_instance_profile.rancher_mgmt_iam_profile.name}"

  security_groups = ["${aws_security_group.rancher_mgmt_sec_group.id}"]

  user_data = "${data.template_file.mgmt_userdata.rendered}"
}

# Create SG for management nodes allowing ingress od ssh, cluster registratation, and web interface
resource "aws_security_group" "rancher_mgmt_sec_group" {
  name        = "rancher-mgmt"
  description = "rancher mgmt security group"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["10.0.0.0/8"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  ingress {
    from_port   = 9345
    to_port     = 9345
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name            = "rancher-mgmt"
    EnvironmentName = "${var.vpc_name}"
    Type            = "EC2"
  }
}

# Create managment node instance proile
resource "aws_iam_instance_profile" "rancher_mgmt_iam_profile" {
  name  = "${var.vpc_name}-rancher-mgmt-${var.aws_region}"
  roles = ["${aws_iam_role.rancher_mgmt_iam_role.name}"]
}

# Create managment node IAM role
resource "aws_iam_role" "rancher_mgmt_iam_role" {
  name = "${var.vpc_name}-rancher-mgmt-${var.aws_region}"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {"AWS": "*"},
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

# Create IAM policy for management nodes
resource "aws_iam_role_policy" "rancher_mgmt_iam_policy" {
  name = "rancher-mgmt-peers"
  role = "${aws_iam_role.rancher_mgmt_iam_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:Describe*",
        "autoscaling:Describe*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

# Create RDS subnet group for rancher management mysql backend
resource "aws_db_subnet_group" "rancher_rds_subnet_group" {
  name       = "rancherdb"
  subnet_ids = ["${var.private_subnets}"]

  tags {
    Name = "Rancher DB subnet group"
  }
}

# Create base empty SG for allowing rancher management nodes access to mysql 
resource "aws_security_group" "rancher_rds_allow_mysql" {
  name        = "allow_rancher_mysql"
  description = "Allow all inbound traffic"
  vpc_id      = "${var.vpc_id}"
}

# Create SG rule for allowing rancher management nodes in all AZ's access to mysql 
resource "aws_security_group_rule" "allow_mysql" {
  count = "${length(var.aws_azs)}"

  type              = "ingress"
  from_port         = 0
  to_port           = "${aws_db_instance.rancher_rds.port}"
  protocol          = "tcp"
  cidr_blocks       = ["${cidrsubnet(var.vpc_cidr, 7, count.index)}"]
  security_group_id = "${aws_security_group.rancher_rds_allow_mysql.id}"
}

# Create rancher mysql backend to store all rancher config
resource "aws_db_instance" "rancher_rds" {
  allocated_storage         = 10
  storage_type              = "gp2"
  engine                    = "mysql"
  identifier                = "rancherdb"
  engine_version            = "5.6.27"
  instance_class            = "db.t1.micro"
  name                      = "${var.dbname}"
  username                  = "${var.root_dbusername}"
  password                  = "${var.root_dbpassword}"
  multi_az                  = "true"
  final_snapshot_identifier = "rancherdb-final-snapshot"
  db_subnet_group_name      = "${aws_db_subnet_group.rancher_rds_subnet_group.name}"
  vpc_security_group_ids    = ["${aws_security_group.rancher_rds_allow_mysql.id}"]
}
