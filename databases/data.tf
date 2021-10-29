data "aws_ami" "centos7" {
  most_recent      = true
  name_regex       = "^Centos-7-DevOps-Practice"   ##ami name
  owners           = ["973714476881"]              ##mai owner id
}
