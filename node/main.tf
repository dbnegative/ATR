resource "aws_autoscaling_group" "rancher_node_asg" {
  name = "Rancher Node ASG"

  desired_capacity = "${var.cluster_size}"
  max_size         = "${var.cluster_size}"
  min_size         = "${var.cluster_size}"

  launch_configuration = "${aws_launch_configuration.rancher_node_launch_config.name}"
  termination_policies = ["OldestInstance"]
  vpc_zone_identifier  = ["${var.private_subnets}"]

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
    value               = "Rancher Node ASG"
    propagate_at_launch = true
  }

  tag {
    key                 = "EnvironmentName"
    value               = "${var.vpc_name}"
    propagate_at_launch = true
  }
}

#data "template_file" "worker_userdata" {
#  template = "${file("${path.module}/userdata.yml.tpl")}"
#
#  vars {
#    bucket             = "${var.cert_bucket}"
#    etcd_dns_name      = "etcd"
#    kubernetes_version = "${Var.kubernetes_version}"
#    path               = "/var/lib/kubernetes"
#    master_dns_name    = "master"
#  }
#}

resource "aws_launch_configuration" "rancher_node_launch_config" {
  lifecycle {
    create_before_destroy = true
  }

  name_prefix = "rancher-node-"

  image_id      = "${var.image_id}"
  instance_type = "t2.medium"
  key_name      = "${var.vpc_name}"

  iam_instance_profile = "${aws_iam_instance_profile.rancher_node_iam_profile.name}"

  security_groups = ["${aws_security_group.rancher_node_sec_group.id}"]

  # user_data = "${data.template_file.worker_userdata.rendered}"
}

resource "aws_security_group" "rancher_node_sec_group" {
  name        = "rancher-node"
  description = "rancher node security group"
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
    Name            = "rancher-node"
    EnvironmentName = "${var.vpc_name}"
    Type            = "EC2"
  }
}

resource "aws_iam_instance_profile" "rancher_node_iam_profile" {
  name  = "${var.vpc_name}-rancher-node-${var.aws_region}"
  roles = ["${aws_iam_role.rancher_node_iam_role.name}"]
}

resource "aws_iam_role" "rancher_node_iam_role" {
  name = "${var.vpc_name}-rancher-node-${var.aws_region}"

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

resource "aws_iam_role_policy" "rancher_node_iam_policy" {
  name = "rancher-node-peers"
  role = "${aws_iam_role.rancher_node_iam_role.id}"

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
