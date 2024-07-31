# Define the AWS provider and region
provider "aws" {
  region = "eu-west-1"
}

# Generate a new RSA private key for SSH access
resource "tls_private_key" "keypair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save the private key to a local file
resource "local_file" "private_key" {
  content         = tls_private_key.keypair.private_key_pem
  filename        = "vault-private-key"
  file_permission = "600" # Set file permissions to be read/write for owner only
}

# Create an AWS key pair using the generated public key
resource "aws_key_pair" "public_key" {
  key_name   = "vault-public-key"
  public_key = tls_private_key.keypair.public_key_openssh
}

# Define the EC2 instance for the Vault server
resource "aws_instance" "vault_server" {
  ami                    = "ami-0c38b837cd80f13bb"
  instance_type          = "t2.medium"
  iam_instance_profile   = aws_iam_instance_profile.vault_instance_profile.name
  key_name               = aws_key_pair.public_key.id
  vpc_security_group_ids = [aws_security_group.vault_sg.id]

  # Use a user data script to initialize Vault on launch
  user_data = templatefile("./vault_script.sh", {
    kms_key        = aws_kms_key.vault.id
    keypair        = tls_private_key.keypair.private_key_pem
    CONSUL_VERSION = "1.7.3"
    VAULT_VERSION  = "1.5.0"
    CONSUL_BIND_IP = "0.0.0.0"
  })

  # Provisioner to clean up the root token file on destruction
  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ./root_token.txt"
  }

  tags = {
    Name = "vault_server"
  }
}

# Create a KMS key for encrypting Vault data
resource "aws_kms_key" "vault" {
  description             = "KMS key for Vault encryption"
  deletion_window_in_days = 10
  tags = {
    Name = "vault-kms-key"
  }
}

# Define the security group for the Vault server
resource "aws_security_group" "vault_sg" {
  name        = "vault-sg"
  description = "Security group for Vault server"

  ingress {
    description = "Allow SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow Vault access"
    from_port   = 8200
    to_port     = 8200
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "vault-sg"
  }
}

data "aws_route53_zone" "ticktocktv" {
  name         = "ticktocktv.com"
  private_zone = false
}

resource "aws_route53_record" "vault_record" {
  zone_id = data.aws_route53_zone.ticktocktv.zone_id
  name    = "vault.ticktocktv.com"
  type    = "A"
  alias {
    name                   = aws_elb.vault_lb.dns_name
    zone_id                = aws_elb.vault_lb.zone_id
    evaluate_target_health = true
  }
}

# Create an ACM certificate
resource "aws_acm_certificate" "acm_cert" {
  domain_name               = "ticktocktv.com"
  subject_alternative_names = ["*.ticktocktv.com"]
  validation_method         = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

# Create Route 53 record for domain validation
resource "aws_route53_record" "validation-record" {
  for_each = {
    for dvo in aws_acm_certificate.acm_cert.domain_validation_options : dvo.domain_name => {
      name    = dvo.resource_record_name
      value   = dvo.resource_record_value
      type    = dvo.resource_record_type
      zone_id = data.aws_route53_zone.ticktocktv.zone_id
    }
  }
  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.value]
  type            = each.value.type
  ttl             = 60
  zone_id         = each.value.zone_id
}

# Validate the ACM certificate
resource "aws_acm_certificate_validation" "cert-validation" {
  certificate_arn         = aws_acm_certificate.acm_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.validation-record : record.fqdn]
}

# Define an Elastic Load Balancer (ELB) for the Vault server
resource "aws_elb" "vault_lb" {
  name                        = "vault-lb"
  availability_zones          = ["eu-west-1b", "eu-west-1c"]
  security_groups             = [aws_security_group.vault_sg.id]
  instances                   = [aws_instance.vault_server.id]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  # Configure the load balancer listener
  listener {
    instance_port      = 8200
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = aws_acm_certificate.acm_cert.arn
  }

  # Define health check for the load balancer
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "TCP:8200"
    interval            = 30
  }

  tags = {
    Name = "vault-elb"
  }
}