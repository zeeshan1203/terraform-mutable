resource "aws_spot_instance_request" "instances" {
  count                       = var.INSTANCE_COUNT
  ami                         = data.aws_ami.centos7.id
  spot_price                  = var.SPOT_PRICE
  instance_type               = var.INSTANCE_TYPE
  vpc_security_group_ids      = [aws_security_group.allow_ec2.id]
  subnet_id                   = element(data.terraform_remote_state.vpc.outputs.PRIVATE_SUBNETS, count.index)
  wait_for_fulfillment        = true

  tags                        = {
    Name                      = "${var.COMPONENT}-${var.ENV}"
    Environment               = var.ENV
  }
}

resource "aws_ec2_tag" "spot" {
  count                       = var.INSTANCE_COUNT
  resource_id                 = element(aws_spot_instance_request.instances.*.spot_instance_id, count.index)
  key                         = "Name"
  value                       = "${var.COMPONENT}-${var.ENV}"
}

resource "aws_ec2_tag" "monitor" {
  count                       = var.INSTANCE_COUNT
  resource_id                 = element(aws_spot_instance_request.instances.*.spot_instance_id, count.index)
  key                         = "Monitor"
  value                       = "yes"
}

resource "aws_ec2_tag" "env" {
  count                       = var.INSTANCE_COUNT
  resource_id                 = element(aws_spot_instance_request.instances.*.spot_instance_id, count.index)
  key                         = "Environment"
  value                       = var.ENV
}

resource "aws_security_group" "allow_ec2" {
  name                        = "allow_${var.COMPONENT}"
  description                 = "allow_${var.COMPONENT}"
  vpc_id                      = data.terraform_remote_state.vpc.outputs.VPC_ID

  ingress {
    description               = "SSH"
    from_port                 = 22
    to_port                   = 22
    protocol                  = "tcp"
    cidr_blocks               = [data.terraform_remote_state.vpc.outputs.VPC_CIDR, data.terraform_remote_state.vpc.outputs.DEFAULT_VPC_CIDR]
  }

  ingress {
    description               = "PROMETHEUS"
    from_port                 = 9100
    to_port                   = 9100
    protocol                  = "tcp"
    cidr_blocks               = [data.terraform_remote_state.vpc.outputs.VPC_CIDR, data.terraform_remote_state.vpc.outputs.DEFAULT_VPC_CIDR]
  }

  ingress {
    description               = "HTTP"
    from_port                 = var.PORT
    to_port                   = var.PORT
    protocol                  = "tcp"
    cidr_blocks               = [data.terraform_remote_state.vpc.outputs.VPC_CIDR]
  }

  egress {
    from_port                 = 0
    to_port                   = 0
    protocol                  = "-1"
    cidr_blocks               = ["0.0.0.0/0"]
    ipv6_cidr_blocks          = ["::/0"]
  }

  tags                        = {
    Name                      = "allow_${var.COMPONENT}"
  }
}

resource "null_resource" "ansible-apply" {
  count                       = var.INSTANCE_COUNT
  triggers = {
    private_ip                = join(",",aws_spot_instance_request.instances.*.private_ip)
  }
  provisioner "remote-exec" {
    connection {
      host                    = element(aws_spot_instance_request.instances.*.private_ip, count.index)
      user                    = jsondecode(data.aws_secretsmanager_secret_version.secrets.secret_string)["SSH_USER"]
      password                = jsondecode(data.aws_secretsmanager_secret_version.secrets.secret_string)["SSH_PASS"]
    }

    inline = [
      "sudo yum install python3-pip -y",
      "sudo pip3 install pip --upgrade",
      "sudo pip3 install ansible==4.1.0",
      "ansible-pull -i localhost, -U https://github.com/zeeshan1203/ansible.git roboshop-pull.yml -e ENV=${var.ENV} -e COMPONENT=${var.COMPONENT}"
      #      "sudo yum install ansible -y",
      #      "sudo yum remove ansible -y",
      #      "sudo rm -rf /usr/lib/python2.7/site-packages/ansible*",
      #      "sudo pip install ansible",
      #      ""ansible-pull -i localhost, -U https://github.com/zeeshan1203/ansible.git roboshop-pull.yml -e ENV=dev -e COMPONENT=${var.COMPONENT}"
    ]

  }
}

resource "aws_lb_target_group" "target-group" {
  name                        = "${var.COMPONENT}-${var.ENV}"
  port                        = var.PORT
  protocol                    = "HTTP"
  vpc_id                      = data.terraform_remote_state.vpc.outputs.VPC_ID
  health_check {
    path                      = var.HEALTH_PATH
    port                      = var.PORT
    interval                  = 10
  }
}

resource "aws_lb_target_group_attachment" "tg-attach" {
  count                       = var.INSTANCE_COUNT
  target_group_arn            = aws_lb_target_group.target-group.arn
  target_id                   = element(aws_spot_instance_request.instances.*.spot_instance_id, count.index)
  port                        = var.PORT
}

resource "aws_lb_listener_rule" "component-rule" {
  listener_arn                = var.LISTENER_ARN
  priority                    = var.LB_RULE_WEIGHT

  action {
    type                      = "forward"
    target_group_arn          = aws_lb_target_group.target-group.arn
  }

  condition {
    host_header {
      values                  = ["${var.COMPONENT}-${var.ENV}.roboshop.internal"]
    }
  }
}

resource "aws_route53_record" "component-record" {
  zone_id                     = data.terraform_remote_state.vpc.outputs.HOSTED_ZONE_ID
  name                        = "${var.COMPONENT}-${var.ENV}.roboshop.internal"
  type                        = "CNAME"
  ttl                         = "300"
  records                     = [var.LB_DNSNAME]
}
