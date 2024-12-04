module "vpc" {
  source = "../../modules/VPC"
  public_nacl=var.public_nacl
  private_nacl_rules=var.private_nacl_rules
  supported_azs=local.supported_azs
  cidr_block=var.cidr_block
}
module "iam"{
    source = "../../modules/IAM"
}
module "ecs" {
   source = "../../modules/ECS"
   ecs_instance_role=module.iam.ec2_role_name
   task_execution_role=module.iam.task_execution_role_arn
   keyname=var.keyname
   vpc_id=module.vpc.vpc_id
   public_subnet_ids=module.vpc.public_subnets
   private_subnet_ids=module.vpc.private_subnets
   image_id = var.image_id
   ami_id = var.ami_id
   availability_zone=var.availability_zone
   ebs_size = var.ebs_size
   instance_type = var.instance_type
   dbcreds_name=var.dbcreds_name
   googleauth_name=var.googleauth_name
}

# resource "aws_s3_bucket" "terraform_state" {
#   bucket = "my-terraform-state-bucket2711"

#   versioning {
#     enabled = true
#   }

# #   lifecycle {
# #     prevent_destroy = true
# #   }

#   tags = {
#     Name        = "Terraform State Bucket"
#     Environment = "Production"
#   }
# }

# resource "aws_dynamodb_table" "terraform_locks" {
#   name         = "terraform-locks"
#   billing_mode = "PAY_PER_REQUEST"

#   attribute {
#     name = "LockID"
#     type = "S"
#   }

#   hash_key = "LockID"

#   tags = {
#     Name        = "Terraform Lock Table"
#     Environment = "Production"
#   }
# }
