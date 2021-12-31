resource "aws_spot_instance_request" "rabbitmq" {
  ami                         = data.aws_ami.centos7.id
  spot_price                  = "0.0031"              ##verify once
  instance_type               = "t3.micro"
  vpc_security_group_ids      = [aws_security_group.allow_rabbitmq.id]
  subnet_id                   = data.terraform_remote_state.vpc.outputs.PRIVATE_SUBNETS[1]
  wait_for_fulfillment        = true

  tags                        = {
    Name                      = "rabbitmq-${var.ENV}"
    Environment               = var.ENV
  }
}

resource "aws_ec2_tag" "rabbitmq" {
  resource_id                 = aws_spot_instance_request.rabbitmq.spot_instance_id
  key                         = "Name"
  value                       = "rabbitmq-${var.ENV}"
}

resource "aws_security_group" "allow_rabbitmq" {
  name                        = "allow_rabbitmq"
  description                 = "AllowRabbitMQ"
  vpc_id                      = data.terraform_remote_state.vpc.outputs.VPC_ID

  ingress {
    description               = "SSH"
    from_port                 = 22
    to_port                   = 22
    protocol                  = "tcp"
    cidr_blocks               = [data.terraform_remote_state.vpc.outputs.VPC_CIDR, data.terraform_remote_state.vpc.outputs.DEFAULT_VPC_CIDR]
  }

  ingress {
    description               = "RABBITMQ"
    from_port                 = 5672
    to_port                   = 5672
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
    Name                      = "AllowRabbitMQ"
  }
}
resource "null_resource" "ansible-rabbitmq" {
  provisioner "remote-exec" {
    connection {
      host                    = aws_spot_instance_request.rabbitmq.private_ip
      user                    = jsondecode(data.aws_secretsmanager_secret_version.secrets.secret_string)["SSH_USER"]
      password                = jsondecode(data.aws_secretsmanager_secret_version.secrets.secret_string)["SSH_PASS"]
    }

    inline = [
      "sudo yum install python3-pip -y",
      "sudo pip3 install pip --upgrade",
      "sudo pip3 install ansible==4.1.0",
      "ansible-pull -i localhost, -U https://github.com/zeeshan1203/ansible.git roboshop-pull.yml -e ENV=${var.ENV} -e COMPONENT=rabbitmq"
      #      "sudo yum install ansible -y",
      #      "sudo yum remove ansible -y",
      #      "sudo rm -rf /usr/lib/python2.7/site-packages/ansible*",
      #      "sudo pip install ansible",
      #      ""ansible-pull -i localhost, -U https://github.com/zeeshan1203/ansible.git roboshop-pull.yml -e ENV=dev -e COMPONENT=${var.COMPONENT}"
    ]

  }
}

resource "aws_route53_record" "rabbitmq-record" {
  zone_id                     = data.terraform_remote_state.vpc.outputs.HOSTED_ZONE_ID
  name                        = "rabbitmq-${var.ENV}.roboshop.internal"
  type                        = "A"
  ttl                         = "300"
  records                     = [aws_spot_instance_request.rabbitmq.private_ip]
}
