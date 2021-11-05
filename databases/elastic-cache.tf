resource "aws_elasticache_cluster" "example" {
  cluster_id                            = "redis-${var.ENV}"
  engine                                = "redis"
  node_type                             = "cache.t3.micro"
  num_cache_nodes                       = 1
  parameter_group_name                  = "default.redis5.0"
  engine_version                        = "5.0.6"
  port                                  = 6379
  security_group_ids                    = [aws_security_group.allow_elastic_redis.id]
  subnet_group_name                     = aws_elasticache_subnet_group.redis-subnet-group.name
}

resource "aws_elasticache_subnet_group" "redis-subnet-group" {
  name                                  = "redis-db-group-${var.ENV}"
  subnet_ids                            = data.terraform_remote_state.vpc.outputs.PRIVATE_SUBNETS

  tags = {
    Name                                = "redis-db-group-${var.ENV}"
    Environment                         = var.ENV
  }
}

resource "aws_security_group" "allow_elastic_redis" {
  name                                  = "allow_elastic_redis"
  description                           = "AllowElasticRedis"
  vpc_id                                = data.terraform_remote_state.vpc.outputs.VPC_ID

  ingress {
    description                         = "REDIS"
    from_port                           = 6379
    to_port                             = 6379
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
    Name                                = "AllowElasticRedis"
    Environment                         = var.ENV
  }
}

resource "aws_route53_record" "elastic-record" {
  zone_id                     = data.terraform_remote_state.vpc.outputs.HOSTED_ZONE_ID
  name                        = "redis-${var.ENV}.roboshop.internal"
  type                        = "CNAME"
  ttl                         = "300"
  records                     = [aws_elasticache_cluster.example.cache_nodes[0].address]
}
