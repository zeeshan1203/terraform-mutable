output "PRIVATE_LB_ARN" {
  value = aws_lb.private.arn
}

output "PUBLIC_LB_ARN" {
  value = aws_lb.public.arn
}

output "PRIVATE_LB_DNSNAME" {
  value = aws_lb.private.dns_name
}

output "PUBLIC_LB_DNSNAME" {
  value = aws_lb.public.dns_name
}
