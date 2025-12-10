resource "aws_ecs_cluster" "watchTower_cluster" {
  name = "watchTower-ecs-cluster"
}

resource "aws_iam_role" "ecs_execution_role" {
    name = "ecsExecutionRole"
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

resource "aws_iam_role_policy_attachment" "ecs_taskexecution_role_policy" {
    role = aws_iam_role.ecs_execution_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_security_group" "ecs_sg" {
  name = "ecs_security_group"
  vpc_id = aws_vpc.watchtower.id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
    description = "Allow HTTP inbound traffic from alb"
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
}

resource "aws_ecs_task_definition" "task" {
  family = "watchTower-task"
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu = "256"
  memory = "512"
  execution_role_arn = aws_iam_role.ecs_execution_role.arn
  container_definitions = jsonencode([
    {
      name = "watchtower-container"
      image = "${aws_ecr_repository.watchtower_repository.repository_url}:latest"
      essential = true
      memory = 512
      cpu = 256
      portMappings = [
        {
          containerPort = 80
          hostPort = 80
          protocol = "tcp"
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "watchTower_service" {
  name = "watchTower-ecs-service"
  cluster = aws_ecs_cluster.watchTower_cluster.id
  task_definition = aws_ecs_task_definition.task.arn
  desired_count = 1
  launch_type = "FARGATE"

  network_configuration {
    subnets = [for subnet in aws_subnet.watchtower_subnet : subnet.id]
    assign_public_ip = true
    security_groups = [aws_security_group.ecs_sg.id]
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.watchtower_tg.arn
    container_name = "watchtower-container"
    container_port = 80
  }
}