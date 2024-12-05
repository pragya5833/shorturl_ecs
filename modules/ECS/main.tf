#to try: task placement strategy and task placement constraint.: binpack,spread and :distinctinstances,instancefamily etc --to
#to try: capacity provider with asg in ecs..task autoscaling and instance autoscaling --to test 
#to try : network mode bridge and target type instance
#to try: secret from sm --done
# understood:
# target group ip then awsvpc but if target group type instance then network mode awsvpc does not work
# with bridge network_mode we can't have network_configuration block in aws service and security group in ntweork config to be passed directly in launch template because eni of container is used and not of containers
# when using target type instance then host port can be dynamic so security group should allow that range . so this condition if hostport not specified.
# when using bridge network then we have to keep containername and containerport in task def and in service
# when using bridge network service discovery must have SRV record type not A - but app doesn't handle SRV hence use awsvpc-- but confirm
# Recommendation for ECS
# For multi-host networking in ECS, the best approach is to use awsvpc network mode, as it provides:

# Native support for multi-host communication.
# Per-task ENIs (Elastic Network Interfaces) with private IPs.
# Simplified security group management.
# If you need Docker Swarm-like behavior, consider using EKS (Elastic Kubernetes Service), which provides better multi-host networking support with features like ClusterIP and LoadBalancer services.
resource "aws_launch_template" "ecs_template" {
  name = "ecs-shorturl-launch-template"
  image_id = var.ami_id
  instance_type = var.instance_type
  key_name = var.keyname
  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance_profile.name
  }
  network_interfaces {
    security_groups = [aws_security_group.ecs_public_sg.id,aws_security_group.ecs_task_sg.id]
  }
  monitoring {
  enabled = true
   }
  user_data = base64encode(templatefile(
    "${path.module}/user_data.sh",
    {
      cluster_name       = aws_ecs_cluster.ecs_cluster.name,
      efs_file_system_id = aws_efs_file_system.postgres_efs.id
    }
  ))
  block_device_mappings {
    device_name = "/dev/xvdf" # Mount the EBS volume
    ebs {
      volume_size           = var.ebs_size
      volume_type           = "gp2"
      delete_on_termination = false
    }
  }
  depends_on = [ aws_efs_file_system.postgres_efs ]
}
# resource "aws_ebs_volume" "postgres_data_volume" {
#   availability_zone = var.availability_zone # Example: "us-east-1a"
#   size              = var.ebs_size          # Size in GB
#   tags = {
#     Name = "postgres-data-volume"
#   }
# }
# Fetch instances in the Auto Scaling Group
data "aws_autoscaling_group" "ecs_autoscaling_group" {
  name = aws_autoscaling_group.ecs_autoscaling.name
}

data "aws_instances" "ecs_instances" {
  filter {
    name   = "tag:aws:autoscaling:groupName"
    values = [data.aws_autoscaling_group.ecs_autoscaling_group.name]
  }
}
# Attach the EBS Volume to an EC2 Instance
# resource "aws_volume_attachment" "postgres_volume_attachment" {
#   device_name = "/dev/xvdf"                             # Device name
#   volume_id   = aws_ebs_volume.postgres_data_volume.id         # EBS Volume ID
#   instance_id = element(data.aws_instances.ecs_instances.ids, 0) # Attach to the first instance
#   force_detach = true # Optional: Ensures volume is detached from other instances before attaching
# }

resource "aws_efs_file_system" "postgres_efs" {
  creation_token = "postgres-efs"
  lifecycle_policy {
    transition_to_ia = "AFTER_7_DAYS"
  }
  tags = {
    Name = "postgres-efs"
  }
}

resource "aws_efs_mount_target" "efs_mount_targets" {
  for_each = {for idx,id in var.private_subnet_ids:idx=>id}
  file_system_id  = aws_efs_file_system.postgres_efs.id
  subnet_id       = each.value
  security_groups = [aws_security_group.efs_sg.id]
}
resource "aws_security_group" "efs_sg" {
  name        = "efs-sg"
  description = "Security group for EFS access"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] # Limit access based on your network requirements
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "efs-security-group"
  }
}
resource "aws_autoscaling_group" "ecs_autoscaling" {
  launch_template {
    version = "$Latest" 
    id=aws_launch_template.ecs_template.id
  }
  vpc_zone_identifier = var.private_subnet_ids
  desired_capacity = 2
  max_size = 2
  min_size = 1
  protect_from_scale_in = true

}
resource "aws_autoscaling_lifecycle_hook" "protect_instances" {
  autoscaling_group_name = aws_autoscaling_group.ecs_autoscaling.name
  lifecycle_transition   = "autoscaling:EC2_INSTANCE_TERMINATING"
  default_result         = "CONTINUE"
  heartbeat_timeout      = 300
  name                   = "scale-in-protection"
}
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "shorturl-ecs-cluster"
}
resource "aws_ecs_task_definition" "nodejs_task_definition" {
  execution_role_arn = var.task_execution_role
  family = "nodeJsTask"
  network_mode = "bridge"
  requires_compatibilities = ["EC2"]
  container_definitions = jsonencode([{
    name="shorturl_backend"
    image=var.image_id
    memory=512
    cpu=256
    essential=true
    environment=[
        {name="REACT_APP_FE_URL",value="https://frontend.deeplink.in"},
        {name="DB_HOST",value="postgres.local"},
        {name="DB_NAME",value="deeplinkurl"},
        {name="DB_PORT",value="5432"},
        {name="DB_SCHEMA",value="deeplink"},
        {name="BE_domain",value="api.deeplink.in"}
    ]
    secrets=[
        {name="DB_USER",valueFrom="${data.aws_secretsmanager_secret.db-username.arn}:username::"},
        {name="DB_PASSWORD",valueFrom="${data.aws_secretsmanager_secret.db-username.arn}:password::"},
        {name="GOOGLE_CLIENT_ID",valueFrom="${data.aws_secretsmanager_secret.google-clientid.arn}:GOOGLE_CLIENT_ID::"},
        {name="GOOGLE_CLIENT_SECRET",valueFrom="${data.aws_secretsmanager_secret.google-clientid.arn}:GOOGLE_CLIENT_SECRET::"},
        {name="SESSION_SECRET",valueFrom="${data.aws_secretsmanager_secret.google-clientid.arn}:SESSION_SECRET::"}
    ]
    # portMappings=[{containerPort=3000}]
    portMappings = [
      {
        containerPort = 3000 # Inside the container
        # hostPort      = 3000 # On the host EC2 instance
      }
    ]
    logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/nodejs-app"
          awslogs-region        = "ap-south-1"
          awslogs-stream-prefix = "ecs"
        }
      }
            placement_strategy= {
        type  = "spread"
        field = "attribute:ecs.availability-zone"
        }
        placement_constraints= {
        type       = "distinctInstance"
        }
  }])
}
# resource "aws_ecs_task_definition" "postgres_task_definition" {
#   execution_role_arn = var.task_execution_role
#   family = "postgresTask"
#   network_mode = "awsvpc"
#   requires_compatibilities = ["EC2"]
#   volume {
#     name      = "postgres-data"
#     host_path = "/mnt/ebs/postgres"
#   }
#   container_definitions = jsonencode([{
#     name= "postgres_backend"
#     image= "postgres:15"
#     memory=512
#     cpu=256
#     essential=true
#     environment=[
#         {name="POSTGRES_DB",value="deeplinkurl"}
#     ]
#     # secrets=[
#     #     {name="POSTGRES_USER",valueFrom="${data.aws_secretsmanager_secret.db_secret.arn}:username"},
#     #     {name="POSTGRES_PASSWORD",valueFrom="${data.aws_secretsmanager_secret.db_secret.arn}:password"}
#     # ]
#     mountPoints=[
#         {
#             sourceVolume="postgres-data"
#             containerPath="/var/lib/postgresql/data"
#             readOnly=false
#         }
#     ]
#     logConfiguration = {
#         logDriver = "awslogs"
#         options = {
#           awslogs-group         = "/ecs/postgres-app"
#           awslogs-region        = "ap-south-1"
#           awslogs-stream-prefix = "ecs"
#         }
#       }
   
#   }])
# }
resource "aws_ecs_task_definition" "postgres_task_definition" {
  execution_role_arn      = var.task_execution_role
  family                  = "postgresTask"
  network_mode            = "awsvpc"
  requires_compatibilities = ["EC2"]

  volume {
    name      = "postgres-data"
    host_path = "/mnt/ebs/postgres/data"
  }
  volume {
    name = "postgres-data-efs"
    efs_volume_configuration {
      file_system_id          = aws_efs_file_system.postgres_efs.id
      root_directory          = "/postgres-data"
      transit_encryption      = "ENABLED"
      authorization_config {
        access_point_id = null
        iam             = "DISABLED"
      }
    }
  }

  container_definitions = jsonencode([{
    name           = "postgres_backend"
    image          = "848417356303.dkr.ecr.ap-south-1.amazonaws.com/postgres:7.0"
    memory         = 512
    cpu            = 256
    essential      = true
    environment    = [
      { name = "POSTGRES_DB", value = "deeplinkurl" },
    #   { name = "POSTGRES_USER", value = "backend" },
    #   { name = "POSTGRES_PASSWORD", value = "backends" }
    ]
    secrets=[
        {name="POSTGRES_USER",valueFrom="${data.aws_secretsmanager_secret.db-username.arn}:username::"},
        {name="POSTGRES_PASSWORD",valueFrom="${data.aws_secretsmanager_secret.db-username.arn}:password::"}
    ]
    mountPoints    = [
      {
        sourceVolume  = "postgres-data-efs"
        containerPath = "/var/lib/postgresql/data"
        readOnly      = false
      }
    ]
    portMappings = [
      { containerPort = 5432 
        # hostPort      = 5432  # Add this line to fix the host port
      } # Add this to define the port
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "/ecs/postgres-app"
        awslogs-region        = "ap-south-1"
        awslogs-stream-prefix = "ecs"
        awslogs-create-group  = "true"
      }
    }
  }])
}

resource "aws_cloudwatch_log_group" "nodejs_log_group" {
  name = "/ecs/nodejs-app"
  retention_in_days = 14  # Optional: Set the retention period as needed
}

resource "aws_cloudwatch_log_group" "postgres_log_group" {
  name = "/ecs/postgres-app"
  retention_in_days = 14  # Optional: Set the retention period as needed
}


resource "aws_iam_instance_profile" "ecs_instance_profile" {
  role = var.ecs_instance_role
}
resource "aws_ecs_service" "nodeJs_service" {
  name            = "nodeJs-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.nodejs_task_definition.arn
  desired_count   = 1
  launch_type     = "EC2"

#   network_configuration {
#     subnets          = var.private_subnet_ids
#     security_groups  = [aws_security_group.ecs_task_sg.id]
#     # assign_public_ip = true  # Set this based on whether your instances need direct internet access
#   }

  load_balancer {
    target_group_arn = aws_lb_target_group.nodejs_target_group.arn
    container_name   = "shorturl_backend"
    container_port   = 3000
  }

  depends_on = [
    aws_lb_listener.http_listener
  ]
}

resource "aws_ecs_service" "postgres_service" {
  name            = "postgres-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.postgres_task_definition.arn
  desired_count   = 1
  launch_type     = "EC2"
  network_configuration {
    subnets = var.private_subnet_ids
    security_groups = [aws_security_group.ecs_task_sg.id]
  }
  service_registries {
    registry_arn = aws_service_discovery_service.postgres.arn
    # container_name  = "postgres_backend"  # Add this
    # container_port  = 5432                # Add this
  }
}
resource "aws_service_discovery_private_dns_namespace" "postgres_namespace" {
  name        = "local"
  description = "Private DNS namespace for service discovery"
  vpc         = var.vpc_id
}
resource "aws_service_discovery_service" "postgres" {
  name = "postgres"
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.postgres_namespace.id
    dns_records {
      ttl = 60
      type = "A"
    }
  }
  health_check_custom_config {
    failure_threshold = 1
  }
}
resource "aws_lb" "nodejs_alb" {
    name = "nodejs-alb"
    internal = false
    load_balancer_type = "application"
    security_groups = [aws_security_group.alb_sg.id]
    subnets = var.public_subnet_ids 
}
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.nodejs_alb.arn
  port = 80
  protocol = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nodejs_target_group.arn
  }
}
resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.nodejs_alb.arn
  port = 443
  protocol = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"

  certificate_arn   = "arn:aws:acm:ap-south-1:848417356303:certificate/47c77462-5a69-4dd7-9da2-39b60f9af2c4"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nodejs_target_group.arn
  }
}
resource "aws_lb_target_group" "nodejs_target_group" {
  name     = "nodejs-target-group"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = "instance"  # Ensure target type is set to 'ip'

  health_check {
    path                = "/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_security_group" "ecs_public_sg" {
  name        = "ecs-public-sg"
  description = "Security group for public ECS service"
  vpc_id      = var.vpc_id

  # Allow HTTP traffic from anywhere
  ingress {
    description = "Allow HTTP traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTPS traffic from anywhere
  ingress {
    description = "Allow HTTPS traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecs-public-sg"
  }
}
resource "aws_security_group" "ecs_task_sg" {
  name        = "ecs-task-sg"
  description = "Security group for ECS tasks"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow PostgreSQL traffic"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "Allow ALB traffic to Node.js"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    description = "Allow ALB traffic to Node.js"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Security group for ALB"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTP traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow HTTPS traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_appautoscaling_target" "nodejs_service_target" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.ecs_cluster.name}/${aws_ecs_service.nodeJs_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = 1
  max_capacity       = 5
}

resource "aws_appautoscaling_policy" "nodejs_service_scale_up" {
  name               = "scale-up"
  resource_id        = aws_appautoscaling_target.nodejs_service_target.resource_id
  scalable_dimension = aws_appautoscaling_target.nodejs_service_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.nodejs_service_target.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }
}

resource "aws_appautoscaling_policy" "nodejs_service_scale_down" {
  name               = "scale-down"
  resource_id        = aws_appautoscaling_target.nodejs_service_target.resource_id
  scalable_dimension = aws_appautoscaling_target.nodejs_service_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.nodejs_service_target.service_namespace # Fixed reference

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }
}


resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  alarm_name                = "ecs-cpu-high"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = 2
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/ECS"
  statistic                 = "Average"
  period                    = 300
  threshold                 = 70
  alarm_description         = "Alarm when CPU exceeds 70%"
  dimensions = {
    ClusterName = aws_ecs_cluster.ecs_cluster.name
  }
  actions_enabled           = true
  alarm_actions             = [aws_appautoscaling_policy.nodejs_service_scale_up.arn]
}

resource "aws_cloudwatch_metric_alarm" "ecs_cpu_low" {
  alarm_name                = "ecs-cpu-low"
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = 2
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/ECS"
  statistic                 = "Average"
  period                    = 300
  threshold                 = 30
  alarm_description         = "Alarm when CPU falls below 30%"
  dimensions = {
    ClusterName = aws_ecs_cluster.ecs_cluster.name
  }
  actions_enabled           = true
  alarm_actions             = [aws_appautoscaling_policy.nodejs_service_scale_down.arn]
}
resource "aws_autoscaling_policy" "scale_out_policy" {
  name                   = "scale-out"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.ecs_autoscaling.name
}

resource "aws_autoscaling_policy" "scale_in_policy" {
  name                   = "scale-in"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.ecs_autoscaling.name
}

resource "aws_cloudwatch_metric_alarm" "ec2_cluster_high_cpu" {
  alarm_name                = "ec2-cluster-high-cpu"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = 2
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  statistic                 = "Average"
  period                    = 300
  threshold                 = 65
  alarm_actions             = [aws_autoscaling_policy.scale_out_policy.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.ecs_autoscaling.name
  }
}

resource "aws_cloudwatch_metric_alarm" "ec2_cluster_low_cpu" {
  alarm_name                = "ec2-cluster-low-cpu"
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = 2
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  statistic                 = "Average"
  period                    = 300
  threshold                 = 30
  alarm_actions             = [aws_autoscaling_policy.scale_in_policy.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.ecs_autoscaling.name
  }
}
resource "aws_ecs_capacity_provider" "ecs_capacity_provider" {
  name = "my-capacity-provider"
  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs_autoscaling.arn
    managed_scaling {
      status                = "ENABLED"
      target_capacity       = 75
      minimum_scaling_step_size = 1
      maximum_scaling_step_size = 5
    }
    managed_termination_protection = "ENABLED"
  }
}

resource "aws_ecs_cluster_capacity_providers" "ecs_cluster_capacity_providers" {
  cluster_name       = aws_ecs_cluster.ecs_cluster.name
  capacity_providers = [aws_ecs_capacity_provider.ecs_capacity_provider.name]
  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ecs_capacity_provider.name
    weight            = 1
  }
}

# resource "aws_ecs_task" "nodejs_task_run" {
#   cluster            = aws_ecs_cluster.main.id
#   task_definition    = aws_ecs_task_definition.nodejs_task.arn
#   network_configuration {
#     subnets         = var.subnets
#     security_groups = [aws_security_group.ecs_task_sg.id]
#     assign_public_ip = false
#   }
# }

# resource "aws_ecs_task" "postgres_task_run" {
#   cluster            = aws_ecs_cluster.main.id
#   task_definition    = aws_ecs_task_definition.postgres_task.arn
#   network_configuration {
#     subnets         = var.subnets
#     security_groups = [aws_security_group.ecs_task_sg.id]
#     assign_public_ip = false
#   }
# }


