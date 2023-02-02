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
