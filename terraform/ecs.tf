resource "aws_kms_key" "lifebit-app-kms" {
  description             = "lifebit-app-kms"
  deletion_window_in_days = 7
}

resource "aws_cloudwatch_log_group" "lifebit-app-log-group" {
  name = "lifebit-app-log-group"
}

# This would provision ECS cluster, service and task definition
resource "aws_ecs_cluster" "lifebit-cluster" {
  name = "lifebit-cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  configuration {
    execute_command_configuration {
      kms_key_id = aws_kms_key.lifebit-app-kms.arn
      logging    = "OVERRIDE"

           log_configuration {
        cloud_watch_encryption_enabled = true
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.lifebit-app-log-group.name
      }
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "lifebit-cp" {
  cluster_name = aws_ecs_cluster.lifebit-cluster.name

  capacity_providers = ["FARGATE"]
    default_capacity_provider_strategy {
    base              = 1
    weight            = 50
    capacity_provider = "FARGATE"
  }
}
resource "aws_ecs_task_definition" "lifebit-task-definition" {
  family = "lifebit-td"
  network_mode = "awsvpc"
  cpu       = 1024
  memory    = 2048
  container_definitions = jsonencode([
    {
      name      = "lifebit-app"
      image     = "faavour/lifebit-image"
      essential = true
      cpu = 512
      memory    = 1024
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
        }
      ]
    }])

       requires_compatibilities = ["FARGATE"]
}
resource "aws_ecs_service" "lifebit-service" {
  name            = "lifebit"
  cluster         = aws_ecs_cluster.lifebit-cluster.id
  task_definition = aws_ecs_task_definition.lifebit-task-definition.arn
  desired_count   = 1
  deployment_maximum_percent         = 200
  depends_on = [
    aws_iam_policy.lifebit-policy  
  ]
   load_balancer {
    target_group_arn = aws_lb_target_group.lifebit-tg.arn
    container_name   = "lifebit-app"
    container_port   = 3000
  }

  network_configuration {
    subnets = var.subnets
    security_groups = [var.security_group_id]
    assign_public_ip = true
  }
}

# For Load balancers
resource "aws_lb" "lifebit-lb" {
  name               = "lifebit-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.security_group_id]
  subnets            = [for subnet in var.subnets : subnet]

  tags = {
    Environment = "production"
  }
}

resource "aws_lb_target_group" "lifebit-tg" {
  name     = "lifebit-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = "ip"
}
resource "aws_lb_listener" "lifebit-lb-listener" {
  load_balancer_arn = aws_lb.lifebit-lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lifebit-tg.arn
  }
}

# For IAM policies 
resource "aws_iam_policy" "lifebit-policy" {
  name = "lifebit-policy"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
    policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
      Effect = "Allow",
      Action = [
        "elb:*",
      ],
      Resource = "*"
    }
    ]
  })
}
resource "aws_iam_role" "lifebit-role" {
  name = "lifebit-role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs-iam-policy-attachment" {
  role       = aws_iam_role.lifebit-role.name
  policy_arn = aws_iam_policy.lifebit-policy.arn
}

resource "aws_iam_role_policy_attachment" "ecs-task-execution-role-policy-attachment" {
  role       = aws_iam_role.lifebit-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs-s3-policy-attachment" {
  role       = aws_iam_role.lifebit-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# Add autoscaling

resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 2
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.lifebit-cluster.name}/${aws_ecs_service.lifebit-service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_policy_cpu" {
  name               = "cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
   predefined_metric_specification {
     predefined_metric_type = "ECSServiceAverageCPUUtilization"
   }
 
   target_value       = 60
  }
}