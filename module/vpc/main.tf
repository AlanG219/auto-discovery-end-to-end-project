resource "aws_vpc" "vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = var.vpc
  }
}
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = var.igw
  }
}
resource "aws_eip" "eip" {
  domain = "vpc"

  tags = {
    Name = var.eip
  }
}
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public_subnet1.id

  tags = {
    Name = var.ngw
  }
}
resource "aws_subnet" "public_subnet1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = var.avz1
  map_public_ip_on_launch = true

  tags = {
    Name = var.pubsn1
  }
}

resource "aws_subnet" "public_subnet2" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = var.avz2
  map_public_ip_on_launch = true

  tags = {
    Name = var.pubsn2
  }
}

resource "aws_subnet" "private_subnet1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = var.avz1

  tags = {
    Name = var.prvsn1
  }
}

resource "aws_subnet" "private_subnet2" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = var.avz2

  tags = {
    Name = var.prvsn2
  }
}
#public route table
resource "aws_route_table" "pub_rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = var.pub_rt
  }
}

#private route table
resource "aws_route_table" "prv_rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = var.prv_rt
  }
}
#Route table associations
resource "aws_route_table_association" "rta_pub1" {
  subnet_id      = aws_subnet.public_subnet1.id
  route_table_id = aws_route_table.pub_rt.id
}

resource "aws_route_table_association" "rta_pub2" {
  subnet_id      = aws_subnet.public_subnet2.id
  route_table_id = aws_route_table.pub_rt.id
}

resource "aws_route_table_association" "rta_prv1" {
  subnet_id      = aws_subnet.private_subnet1.id
  route_table_id = aws_route_table.prv_rt.id
}

resource "aws_route_table_association" "rta_prv2" {
  subnet_id      = aws_subnet.private_subnet2.id
  route_table_id = aws_route_table.prv_rt.id
}
