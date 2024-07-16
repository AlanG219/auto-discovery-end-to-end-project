# ubuntu ami- ami-0c38b837cd80f13bb
# Redhat ami- ami-07d4917b6f95f5c2a
locals {
  name = "pet_auto"
}

# data "aws_acm_certificate" "acm-cert" {
#   domain = "ticktocktv.com" 
#   types       = ["AMAZON_ISSUED"]
#   most_recent = true
# }

module "vpc" {
  source = "./module/vpc"
  avz1   = "eu-west-1b"
  avz2   = "eu-west-1c"
  vpc    = "${local.name}_vpc"
  igw    = "${local.name}_igw"
  ngw    = "${local.name}_ngw"
  eip    = "${local.name}_eip"
  pubsn1 = "${local.name}_pubsn1"
  pubsn2 = "${local.name}_pubsn2"
  prvsn1 = "${local.name}_prvsn1"
  prvsn2 = "${local.name}_prvsn2"
  pub_rt = "${local.name}_pub_rt"
  prv_rt = "${local.name}_prv_rt"
}

module "security_groups" {
  source    = "./module/security_groups"
  vpc-id    = module.vpc.vpc_id
  jenkins   = "${local.name}_jenkins_SG"
  bastion   = "${local.name}_bastion_SG"
  sonarqube = "${local.name}_sonarqube_SG"
  ansible   = "${local.name}_ansible_SG"
  nexus     = "${local.name}_nexus_SG"
  asg       = "${local.name}_asg_SG"
  rds       = "${local.name}_rds_SG"
}

module "keypair" {
  source           = "./module/keypair"
  prv_key_filename = "${local.name}_private_key"
  pub_key_filename = "${local.name}_public_key"
}

module "bastion" {
  source        = "./module/bastion"
  ami           = "ami-0c38b837cd80f13bb"
  subnet_id     = module.vpc.pubsn2_id
  ssh_key       = module.keypair.pub_keypair_id
  instance_type = "t2.micro"
  private_key   = module.keypair.private_key_pem
  name          = "${local.name}_bastion_host"
  bastion_sg    = module.security_groups.bastion-sg
}

module "sonarqube" {
  source                = "./module/sonarqube"
  ami                   = "ami-0c38b837cd80f13bb"
  sonarqube_server_name = "${local.name}_sonarqube"
  instance_type         = "t2.medium"
  key_name              = module.keypair.pub_keypair_id
  sonarqube-sg          = module.security_groups.sonarqube-sg
  subnet_id             = module.vpc.pubsn1_id
}

module "nexus" {
  source       = "./module/nexus"
  red_hat      = "ami-07d4917b6f95f5c2a"
  nexus_subnet = module.vpc.pubsn1_id
  pub_key      = module.keypair.pub_keypair_id
  nexus_sg     = module.security_groups.nexus-sg
  nexus_name   = "${local.name}-nexus"
  subnet-elb = [module.vpc.pubsn1_id, module.vpc.pubsn2_id]
  #cert-arn = data.aws_acm_certificate.acm-cert.arn
  newrelic_api_key = "NRAK-RIPYJAFBUGD6OB6W2RANMN3MYSQ"
  newrelic_account_id = "4466696"
  newrelic_region = "US"
}

module "ansible" {
  source = "./module/ansible"
  red_hat = "ami-07d4917b6f95f5c2a"
  ansible_subnet = module.vpc.prvsn1_id
  pub_key = module.keypair.pub_keypair_id
  ansible_sg = module.security_groups.ansible-sg
  ansible_name = "${local.name}-ansible" 
  stage-playbook = "${path.root}/module/ansible/stage_playbook.yml"
  prod-playbook = "${path.root}/module/ansible/prod_playbook.yml"
  stage-discovery-script = "${path.root}/module/ansible/auto_discovery_stage.tf"
  prod-discovery-script = "${path.root}/module/ansible/auto_discovery_prod.tf"
  private_key = module.keypair.private_key_pem
  nexus-ip = module.nexus.nexus_ip
  newrelic-license-key = "NRAK-RIPYJAFBUGD6OB6W2RANMN3MYSQ"
  newrelic-acct-id = "4466696"  
}

module "prod-lb" {
  source = "./module/prod_lb"
  name = "${local.name}_prod_alb"  
  prod-sg = module.securitygroup.asg-sg
  subnet = [module.vpc.pubsn1_id, module.vpc.pubsn2_id]
  cert-arn = data.aws_acm_certificate.acm-cert.arn
  vpc_id = module.vpc.vpc_id
}

module "stage-lb" {
  source = "./module/stage_lb"
  name = "${local.name}_stage_alb"  
  stage-sg = module.securitygroup.asg-sg
  subnet = [module.vpc.pubsn1_id, module.vpc.pubsn2_id]
  cert-arn = data.aws_acm_certificate.acm-cert.arn
  vpc_id = module.vpc.vpc_id
}

module "prod_asg" {
  source                = "./module/prod_asg"
  ami                   = "ami-07d4917b6f95f5c2a"
  asg-sg                = module.securitygroup.asg-sg
  pub-key               = module.keypair.pub_keypair_id
  nexus-ip              = module.nexus.nexus_ip
  newrelic-user-licence = "NRAK-RIPYJAFBUGD6OB6W2RANMN3MYSQ"
  newrelic-acct-id      = "4466696"
  vpc-zone-identifier   = [module.vpc.pubsn1_id, module.vpc.pubsn2_id]
  policy-name  = "prod-asg-policy"
  tg-arn                = module.prod_lb.tg_prod_arn
  name         = "${local.name}_prod_asg"
  newrelic-region       = "US"
}

module "stage_asg" {
  source                = "./module/stage_asg"
  ami                   = "ami-07d4917b6f95f5c2a"
  asg-sg                = module.securitygroup.asg-sg
  pub-key               = module.keypair.pub_keypair_id
  nexus-ip              = module.nexus.nexus_ip
  newrelic-user-licence = "NRAK-RIPYJAFBUGD6OB6W2RANMN3MYSQ"
  newrelic-acct-id      = "4466696"
  vpc-zone-identifier   = [module.vpc.pubsn1_id, module.vpc.pubsn2_id]
  policy-name  = "stage-asg-policy"
  tg-arn                = module.stage_lb.tg_stage_arn
  name         = "${local.name}_stage_asg"
  newrelic-region       = "US"
}