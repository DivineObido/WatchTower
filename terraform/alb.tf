resource "aws_alb" "watchTower_alb" {
   name = "watchTower-alb"
   load_balancer_type = "application"
   subnets = [for subnet in aws_subnet.watchtower_subnet : subnet.id]
   security_groups = [aws_security_group.alb_sg.id]

   tags = {
    Name = "watchTower ALB"
    Environment = "Dev"
   }
}

resource "aws_security_group" "alb_sg" {
  name = "watchTower-alb-sg"
  vpc_id = aws_vpc.watchtower.id

  ingress {
   from_port = 80
   to_port = 80
   protocol = "tcp"
   cidr_blocks = ["0.0.0.0/0"]
   description = "Allow HTTP inbound traffic from the internet"
  }

  ingress {
   from_port = 443
   to_port = 443
   protocol = "tcp"
   cidr_blocks = ["0.0.0.0/0"]
   description = "Allow HTTPS inbound traffic from the internet"
  }

  egress {
   from_port = 0
   to_port = 0
   protocol = "-1"
   cidr_blocks = ["0.0.0.0/0"]
   description = "Allow all outbound traffic"
  }

}

# Application target Group
resource "aws_alb_target_group" "watchtower_tg" {
  name = "watchtower-tg"
  port = 8080
  protocol = "HTTP"
  vpc_id = aws_vpc.watchtower.id
  target_type =  "ip"

  health_check {
    path = "/health"
    protocol = "HTTP"
    interval = 30
    timeout = 5
    healthy_threshold = 2
    unhealthy_threshold = 3
    port = "8080"
  }
}

# Grafana target Group
resource "aws_alb_target_group" "grafana_tg" {
  name = "grafana-tg"
  port = 3000
  protocol = "HTTP"
  vpc_id = aws_vpc.watchtower.id
  target_type = "ip"
  deregistration_delay = 30

  health_check {
    protocol= "HTTP"
    port = "traffic-port"
    path = "/api/health"
    interval = 30
    timeout = 5
    healthy_threshold = 2
    unhealthy_threshold = 6
    matcher = "200,302"
  }
}

resource "aws_alb_listener" "https_listener" {
  load_balancer_arn = aws_alb.watchTower_alb.arn
  port = 443
  protocol = "HTTPS"
  ssl_policy = "ELBSecurityPolicy-2016-08"

  certificate_arn = aws_acm_certificate.ssl_cert.arn
  default_action {
    type = "forward"
    target_group_arn = aws_alb_target_group.watchtower_tg.arn
  }
}

resource "aws_alb_listener" "http_listener" {
  load_balancer_arn = aws_alb.watchTower_alb.arn
  port = 80
  protocol = "HTTP"
  default_action {
    type = "redirect"
    redirect {
      port = 443
      protocol = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_alb_listener_rule" "grafana_http_listener" {
  listener_arn = aws_alb_listener.http_listener.arn
  priority = 10
  action {
    type = "forward"
    target_group_arn = aws_alb_target_group.grafana_tg.arn
  }
  condition {
    path_pattern {
      values = ["/grafana/*"]
    }
  }
}

