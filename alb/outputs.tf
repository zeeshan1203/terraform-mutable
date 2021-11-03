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

output "PRIVATE_LB_LISTENER_ARN" {
  value = aws_lb_listener.common.arn
}

output "PUBLIC_LB_LISTENER_ARN" {
  value = aws_lb_listener.frontend.arn
}

output "PUBLIC_LB_TARGET_GROUP_ARN" {
  value = aws_lb_target_group.frontend-target-group.arn
}
