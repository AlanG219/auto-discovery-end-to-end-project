output "alb_prod_dns" {
  value = aws_lb.prod_lb.dns_name
}

output "alb_prod_arn" {
  value = aws_lb.prod_lb.arn
}

output "alb_prod_zoneid" {
  value = aws_lb.prod_lb.zone_id 
}

output "tg_prod_arn" {
  value = aws_lb_target_group.lb_tg_prod.arn
}