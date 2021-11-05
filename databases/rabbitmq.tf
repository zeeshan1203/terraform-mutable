resource "aws_mq_broker" "rabbitmq" {
  broker_name                           = "rabbitmq-${var.ENV}"
  deployment_mode                       = "SINGLE_INSTANCE"


  engine_type                           = "RabbitMQ"
  engine_version                        = "3.8.11"
  storage_type                          = "ebs"
  host_instance_type                    = "mq.t3.micro"
  security_groups                       = [aws_security_group.allow_rabbitmq.id]
  subnet_ids                            = [data.terraform_remote_state.vpc.outputs.PRIVATE_SUBNETS[0]]

  user {
    username                            = "roboshop"
    password                            = "roboshop1234"
  }
}

resource "aws_security_group" "allow_rabbitmq" {
  name                                  = "allow_rabbitmq"
  description                           = "AllowRabbitMQ"
  vpc_id                                = data.terraform_remote_state.vpc.outputs.VPC_ID

  ingress {
    description                         = "MYSQL"
    from_port                           = 5672
    to_port                             = 5672
    protocol                            = "tcp"
    cidr_blocks                         = [data.terraform_remote_state.vpc.outputs.VPC_CIDR]
  }

  egress {
    from_port                           = 0
    to_port                             = 0
    protocol                            = "-1"
    cidr_blocks                         = ["0.0.0.0/0"]
    ipv6_cidr_blocks                    = ["::/0"]
  }

  tags                                  = {
    Name                                = "AllowRabbitMQ"
    Environment                         = var.ENV
  }
}

// "console_url" = "https://b-2b25c33c-b240-487f-afbf-bf86d69ac2ff.mq.us-east-1.amazonaws.com"
resource "aws_route53_record" "rabbitmq-record" {
  zone_id                     = data.terraform_remote_state.vpc.outputs.HOSTED_ZONE_ID
  name                        = "rabbitmq-${var.ENV}.roboshop.internal"
  type                        = "CNAME"
  ttl                         = "300"
  records                     = [element(split("/", aws_mq_broker.rabbitmq.instances[0].console_url), 2)]
}

output "rabbitmq" {
  value = aws_mq_broker.rabbitmq
}
