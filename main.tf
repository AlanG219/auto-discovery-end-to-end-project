# ubuntu ami- ami-0c38b837cd80f13bb
# Redhat ami- ami-07d4917b6f95f5c2a
locals {
  name = "pet_auto"
}

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

# Creating bastion host
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

# Creating sonarqube instance
module "sonarqube" {
  source                = "./module/sonarqube"
  ami                   = "ami-0c38b837cd80f13bb"
  sonarqube_server_name = "${local.name}_sonarqube"
  instance_type         = "t2.medium"
  key_name              = module.keypair.pub_keypair_id
  sonarqube-sg          = module.security_groups.sonarqube-sg
  subnet_id             = module.vpc.pubsn1_id
}