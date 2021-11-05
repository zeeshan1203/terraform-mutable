resource "aws_db_instance" "default" {
  identifier                            = "mysql-${var.ENV}"
  allocated_storage                     = 10
  engine                                = "mysql"
  engine_version                        = "5.7"
  instance_class                        = "db.t3.micro"
  name                                  = "defaultlaunched"
  username                              = jsondecode(data.aws_secretsmanager_secret_version.secrets.secret_string)["RDS_MYSQL_USER"]
  password                              = jsondecode(data.aws_secretsmanager_secret_version.secrets.secret_string)["RDS_MYSQL_PASS"]
  parameter_group_name                  = "default.mysql5.7"
  skip_final_snapshot                   = true
  vpc_security_group_ids                = [aws_security_group.allow_rds_mysql.id]
  db_subnet_group_name                  = aws_db_subnet_group.subnet-group.name
  tags                                  = {
    Name                                = "mysql-${var.ENV}"
    Environment                         = var.ENV
  }

}

resource "aws_db_subnet_group" "subnet-group" {
  name                                  = "msyql-db-group-${var.ENV}"
  subnet_ids                            = data.terraform_remote_state.vpc.outputs.PRIVATE_SUBNETS

  tags = {
    Name                                = "msyql-db-group-${var.ENV}"
    Environment                         = var.ENV
  }
}

resource "aws_security_group" "allow_rds_mysql" {
  name                                  = "allow_rds_mysql"
  description                           = "AllowRdsMySQL"
  vpc_id                                = data.terraform_remote_state.vpc.outputs.VPC_ID

  ingress {
    description                         = "MYSQL"
    from_port                           = 3306
    to_port                             = 3306
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
    Name                                = "AllowRdsMySQL"
    Environment                         = var.ENV
  }
}

resource "aws_route53_record" "mysql-record" {
  zone_id                     = data.terraform_remote_state.vpc.outputs.HOSTED_ZONE_ID
  name                        = "mysql-${var.ENV}.roboshop.internal"
  type                        = "CNAME"
  ttl                         = "300"
  records                     = [aws_db_instance.default.address]
}
