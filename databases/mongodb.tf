resource "aws_spot_instance_request" "mongodb" {
  count               = length(var.COMPONENTS)
  ami                 = "ami-074df373d6bafa625"   ##ami id
  spot_price          = "0.0031"                  ##check spot price
  instance_type       = "t3.micro"
  vpc_security_group_ids = ["sg-0d01f7870914fc3d8"]    ##urs security group id

  tags                = {
    Name              = element(var.COMPONENTS, count.index)
  }
}
