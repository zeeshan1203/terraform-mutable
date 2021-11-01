resource "aws_lb" "private" {
  name                        = "alb-private-${var.ENV}"
  internal                    = true
  load_balancer_type          = "application"
  security_groups             = [aws_security_group.allow_privat_lb.id]
  subnets                     = data.terraform_remote_state.vpc.outputs.PRIVATE_SUBNETS
  tags = {
    Environment               = var.ENV
    Name                      = "alb-private-${var.ENV}"
  }
}

resource "aws_security_group" "allow_privat_lb" {
  name                        = "allow_private_lb"
  description                 = "AllowPrivateLB"
  vpc_id                      = data.terraform_remote_state.vpc.outputs.VPC_ID

  ingress {
    description               = "HTTP"
    from_port                 = 80
    to_port                   = 80
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
    Name                      = "AllowPrivateLB"
  }
}

resource "aws_lb_listener" "common" {
  load_balancer_arn           = aws_lb.private.arn
  port                        = "80"
  protocol                    = "HTTP"

  default_action {
    type                      = "fixed-response"

    fixed_response {
      content_type            = "text/plain"
      message_body            = "OK"
      status_code             = "200"
    }
  }
}
