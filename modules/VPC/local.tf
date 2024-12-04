locals {
  public_subnet_ids=[for s in aws_subnet.public_subnet:s.id if s!=null]
  private_subnet_ids=[for s in aws_subnet.private_subnet:s.id if s!=null]
}