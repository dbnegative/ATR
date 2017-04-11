resource "aws_autoscaling_group" "bastion_asg" {
  name = "bastion"

  desired_capacity = 1
  max_size         = 1
  min_size         = 1

  launch_configuration = "${aws_launch_configuration.bastion_launch_config.name}"
  termination_policies = ["OldestInstance"]
  vpc_zone_identifier  = ["${var.private_subnets}"]

  health_check_grace_period = 300
  health_check_type         = "ELB"
  load_balancers            = ["${aws_elb.bastion_elb.name}"]

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
    value               = "bastion"
    propagate_at_launch = true
  }

  tag {
    key                 = "EnvironmentName"
    value               = "${var.name}"
    propagate_at_launch = true
  }
}

resource "template_file" "bastion_cloudinit" {
  lifecycle {
    create_before_destroy = true
  }

  template = <<TEMPLATE
#cloud-config
TEMPLATE
}

resource "aws_launch_configuration" "bastion_launch_config" {
  lifecycle {
    create_before_destroy = true
  }

  name_prefix = "bastion-"

  image_id      = "${var.image_id}"
  instance_type = "t2.medium"
  key_name      = "${var.name}"

  iam_instance_profile = "${aws_iam_instance_profile.bastion_iam_profile.name}"

  security_groups = ["${aws_security_group.bastion_sec_group.id}"]

  user_data = "${template_file.bastion_cloudinit.rendered}"
}

resource "aws_security_group" "bastion_sec_group" {
  name        = "bastion"
  description = "bastion security group"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["10.0.0.0/8"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name            = "bastion"
    EnvironmentName = "${var.name}"
    Type            = "EC2"
  }
}

resource "aws_iam_instance_profile" "bastion_iam_profile" {
  name  = "${var.name}-bastion-${var.aws_region}"
  roles = ["${aws_iam_role.bastion_iam_role.name}"]
}

resource "aws_iam_role" "bastion_iam_role" {
  name = "${var.name}-bastion-${var.aws_region}"

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

# Create rancher aliased A record to rancher mgmt elb
resource "aws_route53_record" "bastion_elb_dns" {
  zone_id = "${var.hosted_zone_id}"
  name    = "bastion.${var.domain}"
  type    = "A"

  alias {
    name                   = "${aws_elb.bastion_elb.dns_name}"
    zone_id                = "${aws_elb.bastion_elb.zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_elb" "bastion_elb" {
  name    = "bastion"
  subnets = ["${var.public_subnets}"]

  security_groups = ["${aws_security_group.bastion_elb_sec_group.id}"]

  listener {
    instance_port     = 22
    instance_protocol = "tcp"
    lb_port           = 22
    lb_protocol       = "tcp"
  }

  health_check {
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 3
    target              = "TCP:22"
    interval            = 5
  }

  cross_zone_load_balancing   = true
  idle_timeout                = 300
  connection_draining         = true
  connection_draining_timeout = 5

  tags {
    Name            = "bastion"
    EnvironmentName = "${var.name}"
    Type            = "ELB"
  }
}

resource "aws_security_group" "bastion_elb_sec_group" {
  name        = "bastion-elb"
  description = "bastion ELB security group"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "TCP"
    security_groups = ["${aws_security_group.bastion_sec_group.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name            = "bastion"
    EnvironmentName = "${var.name}"
    Type            = "ELB"
  }
}
