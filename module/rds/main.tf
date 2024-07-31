# create db subnet group
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = var.rds_subgroup
  subnet_ids = var.rds_subnet_id

  tags = {
    Name = var.db_subtag
  }
}
# create aws db instance
resource "aws_db_instance" "petclinic" {
  identifier             = "petclinic"
  engine                 = "mysql"
  engine_version         = "5.7"
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = var.rds_sg
  allocated_storage      = 10
  instance_class         = "db.t3.micro"
  parameter_group_name   = "default.mysql5.7"
  storage_type           = "gp2"
  skip_final_snapshot    = true
  publicly_accessible    = false
}