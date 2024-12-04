resource "aws_iam_role" "ecs_cluster_role" {
  name="ecs-cluster-role-newcluster"
  assume_role_policy = jsonencode({
    Version="2012-10-17",
    Statement=[
        {
            Effect="Allow",
            Principal={
                Service="ecs.amazonaws.com"
            },
            Action="sts:AssumeRole"
        }
    ]
  })
}
resource "aws_iam_policy" "ecs_cluster_policy" {
  name="ecs_cluster_policy-newcluster"
  policy = jsonencode({
    Version="2012-10-17",
    Statement=[
       {
        Effect="Allow",
        Action=[
             "ecs:CreateCluster",
          "ecs:DeleteCluster",
          "ecs:DescribeClusters",
          "ecs:ListClusters",
          "ecs:DescribeServices",
          "ecs:UpdateService",
          "ecs:ListServices",
          "ecs:DescribeTasks",
          "ecs:ListTasks",
          "elasticfilesystem:DescribeFileSystems",
        "elasticfilesystem:DescribeMountTargets",
        "elasticfilesystem:DescribeAccessPoints",
        "elasticfilesystem:ListTagsForResource",
        "elasticfilesystem:ClientMount",
    "elasticfilesystem:ClientWrite"
        ],
        Resource="*"
       }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "ecs_cluster_policy_attach" {
  role = aws_iam_role.ecs_cluster_role.name
  policy_arn = aws_iam_policy.ecs_cluster_policy.arn
}

resource "aws_iam_role" "ecs_task_role" {
  name="ecs-task-role-newcluster"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement=[
        {
            Effect="Allow",
            Principal={
                Service="ecs-tasks.amazonaws.com"
            },
            Action = "sts:AssumeRole"
        }
    ]
  })
}
resource "aws_iam_policy" "ecs_task_policy" {
  name = "ecs-task-policy-newcluster"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "secretsmanager:GetSecretValue",
          "s3:GetObject",
          "s3:PutObject",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "elasticfilesystem:DescribeFileSystems",
        "elasticfilesystem:DescribeMountTargets",
        "elasticfilesystem:DescribeAccessPoints",
        "elasticfilesystem:ListTagsForResource",
        "elasticfilesystem:ClientMount",
    "elasticfilesystem:ClientWrite"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "task_policy_attachment" {
  role = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_task_policy.arn
}

resource "aws_iam_role" "task_execution_role" {
  name="task-execution-role-newcluster"
  assume_role_policy = jsonencode({
    Version="2012-10-17",
    Statement=[
        {
            Effect="Allow",
            Principal={
                Service="ecs-tasks.amazonaws.com"
            },
            Action="sts:AssumeRole"
        }
    ]
  })
}
resource "aws_iam_policy" "task_execution_policy" {
  name = "task-execution-policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "secretsmanager:GetSecretValue",
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "elasticfilesystem:DescribeFileSystems",
        "elasticfilesystem:DescribeMountTargets",
        "elasticfilesystem:DescribeAccessPoints",
        "elasticfilesystem:ListTagsForResource",
        "elasticfilesystem:ClientMount",
    "elasticfilesystem:ClientWrite"
      ],
      Resource = "*"
    }]
  })
}


resource "aws_iam_role_policy_attachment" "task_execution_policy_attachment" {
  role=aws_iam_role.task_execution_role.name
  policy_arn = aws_iam_policy.task_execution_policy.arn
}

resource "aws_iam_role" "ecs_autoscaling_role" {
  name = "ecs-autoscaling-role-newcluster"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "application-autoscaling.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "ecs_autoscaling_policy" {
  name="ecs-autoscaling-policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement=[
        { Effect   = "Allow",
        Action   = [
          "application-autoscaling:*",
          "cloudwatch:*"
        ],
        Resource = "*"}
    ]
  })
}
resource "aws_iam_role_policy_attachment" "ecs_autoscaling_policy_attachment" {
  role = aws_iam_role.ecs_autoscaling_role.name
  policy_arn = aws_iam_policy.ecs_autoscaling_policy.arn
}
resource "aws_iam_policy" "ecs_logging" {
  name        = "ecs-logging-policy"
  description = "Allow ECS tasks to write logs to CloudWatch Logs"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:CreateLogGroup"
        ],
        Resource = [
          "arn:aws:logs:*:*:log-group:/ecs/nodejs-app:*",
          "arn:aws:logs:*:*:log-group:/ecs/postgres-app:*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "ecs_logging_attachment" {
  name       = "ecs-logging-attachment"
  policy_arn = aws_iam_policy.ecs_logging.arn
  roles      = [aws_iam_role.task_execution_role.name]
}

resource "aws_iam_role" "ecs_instance_role" {
  name = "ecs-instance-role-newcluster"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "ecs_instance_policy" {
  name = "ecs-instance-policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "ecs:CreateCluster",
          "ecs:RegisterContainerInstance",
          "ecs:DeregisterContainerInstance",
          "ecs:DiscoverPollEndpoint",
          "ecs:DescribeContainerInstances",
          "ecs:DescribeTasks",
          "ecs:Poll",
          "ecs:Submit*",
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "elasticfilesystem:ClientMount",
    "elasticfilesystem:ClientWrite"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_instance_policy_attachment" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = aws_iam_policy.ecs_instance_policy.arn
}
resource "aws_iam_role_policy_attachment" "ecs_instance_policy_attachment_existing" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

