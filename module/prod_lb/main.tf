# Creating Application Load Balancer for ASG Prod
resource "aws_lb" "prod_lb" {
  name                       = var.name
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [var.prod-sg]
  subnets                    = var.subnet
  enable_deletion_protection = false

  tags = {
    Name = var.name
  }
}

# Creating Load Balancer Target Group for ASG Prod
resource "aws_lb_target_group" "lb_tg_prod" {
  name     = "lb_tg_prod"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    interval            = 30
    timeout             = 10
    healthy_threshold   = 3
    unhealthy_threshold = 5
  }
}
# Creating Load Balancer Listener for HTTP with redirect to HTTPS
resource "aws_lb_listener" "lb_lsnr-http" {
  load_balancer_arn = aws_lb.prod_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = 443
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# Creating Load Balancer Listener for HTTPS
resource "aws_lb_listener" "lb_lsnr-https" {
  load_balancer_arn = aws_lb.prod_lb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.cert-arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_tg_prod.arn
  }
}
