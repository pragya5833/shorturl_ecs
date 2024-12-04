output "private_subnets" {
  value = aws_subnet.private_subnet.*.id
}
output "public_subnets" {
  value = aws_subnet.public_subnet.*.id
}
output "vpc_id" {
  value = aws_vpc.main.id
}