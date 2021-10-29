resource "aws_spot_instance_request" "mongodb" {
  ami                         = data.aws_ami.centos7.id
  spot_price                  = "0.0031"
  instance_type               = "t3.micro"
  vpc_security_group_ids      = [aws_security_group.allow_mongodb.id]
  subnet_id                   = data.terraform_remote_state.vpc.outputs.PRIVATE_SUBNETS[1]

  tags                        = {
    Name                      = "mongodb-${var.ENV}"
    Environment               = var.ENV
  }
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

//
//resource "null_resource" "ansible-mongo" {
//  provisioner "local-exec" {
//    command                   = "sleep 30"
//  }
//
//  provisioner "remote-exec" {
//    connection {
//      host                    = aws_spot_instance_request.mongodb.private_ip
//      user                    =
//    }
//  }
//}
