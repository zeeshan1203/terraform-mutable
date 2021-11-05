resource "aws_spot_instance_request" "mongodb" {
  ami                         = data.aws_ami.centos7.id
  spot_price                  = "0.0031"
  instance_type               = "t3.micro"
  vpc_security_group_ids      = [aws_security_group.allow_mongodb.id]
  subnet_id                   = data.terraform_remote_state.vpc.outputs.PRIVATE_SUBNETS[1]
  wait_for_fulfillment        = true

  tags                        = {
    Name                      = "mongodb-${var.ENV}"
    Environment               = var.ENV
  }
}

resource "aws_ec2_tag" "mongo" {
  resource_id                 = aws_spot_instance_request.mongodb.spot_instance_id
  key                         = "Name"
  value                       = "mongodb-${var.ENV}"
}

resource "aws_security_group" "allow_mongodb" {
  name                        = "allow_mongodb"
  description                 = "AllowMongoDB"
  vpc_id                      = data.terraform_remote_state.vpc.outputs.VPC_ID

  ingress {
    description               = "SSH"
    from_port                 = 22
    to_port                   = 22
    protocol                  = "tcp"
    cidr_blocks               = [data.terraform_remote_state.vpc.outputs.VPC_CIDR, data.terraform_remote_state.vpc.outputs.DEFAULT_VPC_CIDR]
  }

  ingress {
    description               = "MONGODB"
    from_port                 = 27017
    to_port                   = 27017
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
    Name                      = "AllowMongoDB"
  }
}

resource "null_resource" "wait" {
  provisioner "local-exec" {
    command                   = "sleep 30"
  }
}

resource "null_resource" "ansible-mongo" {
  depends_on = [null_resource.wait]
  provisioner "remote-exec" {
    connection {
      host                    = aws_spot_instance_request.mongodb.private_ip
      user                    = jsondecode(data.aws_secretsmanager_secret_version.secrets.secret_string)["SSH_USER"]
      password                = jsondecode(data.aws_secretsmanager_secret_version.secrets.secret_string)["SSH_PASS"]
    }

    inline = [
      "sudo yum install python3-pip -y",
      "sudo pip3 install pip --upgrade",
      "sudo pip3 install ansible",
      "ansible-pull -i localhost, -U https://github.com/zeeshan1203/ansible.git roboshop-pull.yml -e COMPONENT=mongodb"
      #      "sudo yum install ansible -y",
      #      "sudo yum remove ansible -y",
      #      "sudo rm -rf /usr/lib/python2.7/site-packages/ansible*",
      #      "sudo pip install ansible",
      #      "ansible-pull -i localhost, -U https://DevOps-Batches@dev.azure.com/DevOps-Batches/DevOps56/_git/ansible roboshop-pull.yml -e COMPONENT=mongodb"
    ]

  }
}

resource "aws_route53_record" "mongodb-record" {
  zone_id                     = data.terraform_remote_state.vpc.outputs.HOSTED_ZONE_ID
  name                        = "mongodb-${var.ENV}.roboshop.internal"
  type                        = "A"
  ttl                         = "300"
  records                     = [aws_spot_instance_request.mongodb.private_ip]
}
