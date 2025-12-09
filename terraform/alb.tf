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

resource "aws_alb_target_group" "watchtower_tg" {
  name = "watchtower-tg"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.watchtower.id
  target_type =  "ip"

  health_check {
    path = "/"
  }
}

resource "aws_alb_listener" "https_listener" {
  load_balancer_arn = aws_alb.watchTower_alb.arn
  port = 443
  protocol = "HTTPS"
   ssl_policy = "ELBSecurityPolicy-2016-08"
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

