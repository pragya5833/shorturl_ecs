locals {
  supported_azs=[for az in data.aws_availability_zones.available.names:az if az!=var.excluded_az]
}