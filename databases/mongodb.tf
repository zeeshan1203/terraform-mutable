//resource "aws_spot_instance_request" "mongodb" {
//  count               = length(var.COMPONENTS)
//  ami                 = ""
//  spot_price          = "0.0031"
//  instance_type       = "t3.micro"
//  vpc_security_group_ids = ["sg-0d01f7870914fc3d8"]
//
//  tags                = {
//    Name              = element(var.COMPONENTS, count.index)
//  }
//}
