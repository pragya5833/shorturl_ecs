provider "aws" {
  region = "ap-south-1"
}
# Temporarily use the local backend for state
terraform {
  backend "local" {
    path = "./terraform.tfstate"
  }
}
