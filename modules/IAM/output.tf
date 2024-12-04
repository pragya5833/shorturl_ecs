output "task_execution_role_arn" {
  value = aws_iam_role.task_execution_role.arn
}
output "task_role_arn" {
  value = aws_iam_role.ecs_task_role.arn
}
output "autoscaling_role_arn" {
  value = aws_iam_role.ecs_autoscaling_role.arn
}
output "ec2_role_arn" {
  value = aws_iam_role.ecs_instance_role.arn
}
output "ec2_role_name" {
  value = aws_iam_role.ecs_instance_role.name
}
output "ecs_cluster_role_arn" {
  value = aws_iam_role.ecs_cluster_role.arn
}