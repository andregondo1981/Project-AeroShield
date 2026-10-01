# Application Load Balancer spanning across 2 public subnets (Multi-AZ Redundancy)
resource "aws_lb" "utc_alb" {
  name               = "utc-application-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  enable_deletion_protection = false

  tags = {
    Name = "utc-application-alb"
  }
}

# Target Group
# Target Group
resource "aws_lb_target_group" "utc_tg" {
  name        = "utc-target-group"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200,302"  # <--- Updated: Accept both 200 OK and redirects
    interval            = 60         # <--- Increased to give Spring Boot enough time to start
    timeout             = 10         # <--- Increased timeout window
    healthy_threshold   = 2
    unhealthy_threshold = 5          # <--- More forgiving before marking unhealthy
  }

  tags = {
    Name = "utc-target-group"
  }
}

# ALB HTTP Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.utc_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.utc_tg.arn
  }
}


