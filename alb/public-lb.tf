resource "aws_lb" "public" {
  name                        = "alb-public-${var.ENV}"
  internal                    = false
  load_balancer_type          = "application"
  security_groups             = [aws_security_group.allow_privat_lb.id]
  subnets                     = data.terraform_remote_state.vpc.outputs.PUBLIC_SUBNETS
  tags = {
    Environment               = var.ENV
    Name                      = "alb-public-${var.ENV}"
  }
}

resource "aws_security_group" "allow_public_lb" {
  name                        = "allow_public_lb"
  description                 = "AllowPublicLB"
  vpc_id                      = data.terraform_remote_state.vpc.outputs.VPC_ID

  ingress {
    description               = "HTTP"
    from_port                 = 80
    to_port                   = 80
    protocol                  = "tcp"
    cidr_blocks               = ["0.0.0.0/0"]
  }

  egress {
    from_port                 = 0
    to_port                   = 0
    protocol                  = "-1"
    cidr_blocks               = ["0.0.0.0/0"]
    ipv6_cidr_blocks          = ["::/0"]
  }

  tags                        = {
    Name                      = "AllowPublicLB"
  }
}
