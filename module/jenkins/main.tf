resource  "aws_instance" "jenkins" {
  ami                         = var.ami-redhat
  instance_type               = "t3.medium"
  subnet_id                   = var.subnet-id
  vpc_security_group_ids      = [var.jenkins-sg]
  key_name                    = var.key-name 
  user_data                   = local.jenkins_script

  tags = {
    Name = var.jenkins-name
  }
}
  
resource "aws_lb" "jenkins_lb" {
  name                       = "jenkins_lb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [var.jenkins-sg]
  subnets                    = var.subnet-elb
  enable_deletion_protection = false

  tags = {
    Name = "jenkins_alb"
  }
}

# Creating Load Balancer Target Group for Jenkins
resource "aws_lb_target_group" "jenkins_lb_tg" {
  name     = "jenkins_lb_tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    interval            = 30
    timeout             = 3
    healthy_threshold   = 3
    unhealthy_threshold = 5
  }
}
resource "aws_lb_target_group_attachment" "tg_att" {
  target_group_arn = aws_lb_target_group.jenkins_lb_tg.arn
  target_id        = aws_instance.jenkins.id
  port             = 8080
}

# Creating Load Balancer Listener for HTTP with redirect to HTTPS
resource "aws_lb_listener" "j_lb_lsnr-http" {
  load_balancer_arn = aws_lb.jenkins_lb.arn
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
resource "aws_lb_listener" "j_lb_lsnr-https" {
  load_balancer_arn = aws_lb.jenkins_lb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.cert-arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.jenkins_lb_tg.arn
  }
}