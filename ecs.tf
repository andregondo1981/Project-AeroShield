# 1. Amazon ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "utc-application-cluster"

  tags = {
    Name = "utc-application-cluster"
  }
}

# 2. CloudWatch Log Group for ECS Container Logs
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/utc-application"
  retention_in_days = 30
}

# 3. ECS Task Definition (Fargate)
resource "aws_ecs_task_definition" "app" {
  family                   = "utc-app-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "webapp"
      image     = "nginx:1.25-alpine-slim" # Initial placeholder image before CI/CD pipeline pushes updates
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_logs.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

# 4. ECS Service (Running across private subnets and attached to ALB Target Group)
resource "aws_ecs_service" "app" {
  name            = "utc-app-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 2 # Multi-redundancy across AZs
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.private_app_1.id, aws_subnet.private_app_2.id]
    security_groups  = [aws_security_group.app_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.utc_tg.arn
    container_name   = "webapp"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.http]
}

# --- IAM Roles Required for ECS Fargate Execution ---
resource "aws_iam_role" "ecs_execution_role" {
  name = "utc-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task_role" {
  name = "utc-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}