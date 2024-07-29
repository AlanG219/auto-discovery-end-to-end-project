# Create the Route 53 hosted zone
resource "aws_route53_zone" "ticktocktv" {
  name         = var.domain_name1
}

# Create an ACM certificate
resource "aws_acm_certificate" "certificate" {
  domain_name               = var.domain_name1
  subject_alternative_names = [var.domain_name2]
  validation_method         = "DNS"
}

# Create Route 53 record for domain validation
resource "aws_route53_record" "validation-record" {
  for_each = {
    for dvo in aws_acm_certificate.certificate.domain_validation_options : dvo.domain_name => {
      name    = dvo.resource_record_name
      value   = dvo.resource_record_value
      type    = dvo.resource_record_type
      zone_id = aws_route53_zone.ticktocktv.zone_id
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
  certificate_arn         = aws_acm_certificate.certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.validation-record : record.fqdn]
}

resource "aws_route53_record" "jenkins_record" {
  zone_id = data.aws_route53_zone.route53_zone.zone_id
  name    = var.jenkins_domain_name
  type    = "A"
  alias {
    name                   = var.jenkins_lb_dns_name
    zone_id                = var.jenkins_lb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "nexus_record" {
  zone_id = data.aws_route53_zone.route53_zone.zone_id
  name    = var.nexus_domain_name
  type    = "A"
  alias {
    name                   = var.nexus_lb_dns_name
    zone_id                = var.nexus_lb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "sonarqube_record" {
  zone_id = data.aws_route53_zone.route53_zone.zone_id
  name    = var.sonarqube_domain_name
  type    = "A"
  alias {
    name                   = var.sonarqube_lb_dns_name
    zone_id                = var.sonarqube_lb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "prod_record" {
  zone_id = data.aws_route53_zone.route53_zone.zone_id
  name    = var.prod_domain_name
  type    = "A"
  alias {
    name                   = var.prod_lb_dns_name
    zone_id                = var.prod_lb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "stage_record" {
  zone_id = data.aws_route53_zone.route53_zone.zone_id
  name    = var.stage_domain_name
  type    = "A"
  alias {
    name                   = var.stage_lb_dns_name
    zone_id                = var.stage_lb_zone_id
    evaluate_target_health = true
  }
}