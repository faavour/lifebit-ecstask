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

resource "aws_lb_target_group" "lifebit-tg" {
  name     = ""
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = "ip"
}