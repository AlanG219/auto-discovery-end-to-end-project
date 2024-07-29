terraform {
  backend "s3" {
    bucket         = "pet-auto-remote-tfstate"
    key            = "root-tf-state/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "pet-auto-dynamodb-tfstate"
    encrypt        = true
  }
}
