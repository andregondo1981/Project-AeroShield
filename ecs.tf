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
      image     = "nginx:1.25-alpine-slim" # Will be overwritten or updated by your CI/CD pipeline
      essential = true
      portMappings = [
        {
          containerPort = 8080  # <--- Changed from 80 to 8080
          hostPort      = 8080  # <--- Changed from 80 to 8080
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

# 4. ECS Service (Running across public subnets and attached to ALB Target Group)
resource "aws_ecs_service" "app" {
  name                 = "utc-app-service"
  cluster              = aws_ecs_cluster.main.id
  task_definition      = aws_ecs_task_definition.app.arn
  desired_count        = 2 
  launch_type          = "FARGATE"
  force_new_deployment = true # <--- Automates pipeline rollouts without manual click-ops!

  network_configuration {
    subnets          = [aws_subnet.public_1.id, aws_subnet.public_2.id] 
    security_groups  = [aws_security_group.app_sg.id]               
    assign_public_ip = true                                          
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.utc_tg.arn
    container_name   = "webapp"
    container_port   = 8080  # <--- Changed from 80 to 8080 to match the container mapping
  }

  depends_on = [aws_lb_listener.http]
}