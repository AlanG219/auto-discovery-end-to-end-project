output "alb_stage_dns" {
  value = aws_lb.stage_lb.dns_name
}

output "alb_stage_arn" {
  value = aws_lb.stage_lb.arn
}

output "alb_stage_zoneid" {
  value = aws_lb.stage_lb.zone_id 
}

output "tg_stage_arn" {
  value = aws_lb_target_group.lb_tg_stage.arn
}