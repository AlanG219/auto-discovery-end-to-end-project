resource "aws_instance" "sonarqube" {
  ami                         = var.ami
  instance_type               = var.instance_type
  key_name                    = var.key_name
  vpc_security_group_ids      = [var.sonarqube-sg]
  subnet_id                   = var.subnet_id
  associate_public_ip_address = true
  user_data                   = local.sonarqube_script
  tags = {
    Name = var.sonarqube_server_name
  }
}

resource "aws_elb" "sonarqube_lb" {
  name            = "sonarqube-lb"
  subnets         = var.subnet-elb
  security_groups = [var.sonarqube-sg]
  listener {
    instance_port      = 9000
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = var.cert-arn
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "TCP:9000"
    interval            = 30
  }

  instances                   = [aws_instance.sonarqube.id]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "sonarqube-elb"
  }
}