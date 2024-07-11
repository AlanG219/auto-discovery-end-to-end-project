#Create nexus server
resource "aws_instance" "nexus" {
  ami                         = var.red_hat
  instance_type               = "t2.medium"
  associate_public_ip_address = true
  subnet_id                   = var.nexus_subnet
  key_name                    = var.pub_key
  vpc_security_group_ids      = [var.nexus_sg]
  user_data = local.nexus_user_data
  tags = {
    Name = var.nexus_name
  }
}

resource "aws_elb" "nexus_lb" {
  name            = "nexus-lb"
  subnets         = var.subnet-elb 
  security_groups = [var.nexus_sg]
  listener {
    instance_port      = 8081
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = var.cert-arn
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "TCP:8081"
    interval            = 30
  }

    instances                   = [aws_instance.nexus.id]
    cross_zone_load_balancing   = true
    idle_timeout                = 400
    connection_draining         = true
    connection_draining_timeout = 400

    tags = {
      Name = "nexus-elb"
  }
}