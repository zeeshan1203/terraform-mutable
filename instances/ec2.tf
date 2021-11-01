resource "aws_spot_instance_request" "instances" {
  count                       = var.INSTANCE_COUNT
  ami                         = data.aws_ami.centos7.id
  spot_price                  = var.SPOT_PRICE
  instance_type               = var.INSTANCE_TYPE
  vpc_security_group_ids      = [aws_security_group.allow_ec2.id]
  subnet_id                   = element(data.terraform_remote_state.vpc.outputs.PRIVATE_SUBNETS, count.index)

  tags                        = {
    Name                      = "${var.COMPONENT}-${var.ENV}"
    Environment               = var.ENV
  }
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

resource "null_resource" "wait" {
  triggers                    = {
    abc                       = timestamp()
  }
  provisioner "local-exec" {
    command                   = "sleep 30"
  }
}

resource "null_resource" "ansible-apply" {
  count                       = var.INSTANCE_COUNT
  depends_on                  = [null_resource.wait]
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
      "ansible-pull -i localhost, -U https://github.com/zeeshan1203/ansible.git roboshop-pull.yml -e COMPONENT=mongodb"
      #      "sudo yum install ansible -y",
      #      "sudo yum remove ansible -y",
      #      "sudo rm -rf /usr/lib/python2.7/site-packages/ansible*",
      #      "sudo pip install ansible",
      #      "ansible-pull -i localhost, -U https://DevOps-Batches@dev.azure.com/DevOps-Batches/DevOps56/_git/ansible roboshop-pull.yml -e COMPONENT=mongodb"
    ]

  }
}
