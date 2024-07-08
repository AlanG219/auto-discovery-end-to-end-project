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