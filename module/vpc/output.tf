output "vpc_id" {
  value = aws_vpc.vpc.id
}
output "igw_id" {
  value = aws_internet_gateway.igw.id
}
output "ngw_id" {
  value = aws_nat_gateway.nat_gw.id
}
output "pubsn1_id" {
  value = aws_subnet.public_subnet1.id
}
output "pubsn2_id" {
  value = aws_subnet.public_subnet2.id
}
output "prvsn1_id" {
  value = aws_subnet.private_subnet1.id
}
output "prvsn2_id" {
  value = aws_subnet.private_subnet2.id
}


