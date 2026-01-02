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
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
    description = "Allow HTTP inbound traffic from alb listening on port 8080"
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
}

# resource "aws_ecs_task_definition" "task" {
#   family = "watchTower-task"
#   network_mode = "awsvpc"
#   requires_compatibilities = ["FARGATE"]
#   cpu = "256"
#   memory = "512"
#   execution_role_arn = aws_iam_role.ecs_execution_role.arn
#   container_definitions = jsonencode([
#     {
#       name = "frontend"
#       image = "${aws_ecr_repository.watchtower_repository.repository_url}:frontend-latest"
#       essential = true
#       portMappings = [
#         {
#           containerPort = 80
#         }
#       ]
#     },
#     {
#       name = "emailservice"
#       image = "${aws_ecr_repository.watchtower_repository.repository_url}:email-latest"
#       essential = true
#       portMappings = [
#         {
#           containerPort = 8080
#         }
#       ]
#     },
#     {
#       name = "shoppingassistantservice"
#       image = "${aws_ecr_repository.watchtower_repository.repository_url}:shopping-latest"
#       essential = true
#       portMappings = [
#         {
#           containerPort = 8081
#         }
#       ]
#     },
#     {
#       name = "checkoutservice"
#       image = "${aws_ecr_repository.watchtower_repository.repository_url}:checkout-latest"
#       essential = true
#       portMappings = [
#         {
#           containerPort = 5050
#         }
#       ]
#     },
#     {
#       name = "shippingservice"
#       image = "${aws_ecr_repository.watchtower_repository.repository_url}:shipping-latest"
#       essential = true
#       portMappings = [
#         {
#           containerPort = 50051
#         }
#       ]
#     },
#     {
#       name = "recommendationservice"
#       image = "${aws_ecr_repository.watchtower_repository.repository_url}:recommendation-latest"
#       essential = true
#       portMappings = [
#         {
#           containerPort = 8082
#         }
#       ]
#     },
#     {
#       name = "cartservice"
#       image = "${aws_ecr_repository.watchtower_repository.repository_url}:cart-latest"
#       essential = true
#       portMappings = [
#         {
#           containerPort = 7070
#         }
#       ]
#     },
#     {
#       name = "currencyservice"
#       image = "${aws_ecr_repository.watchtower_repository.repository_url}:currency-latest"
#       essential = true
#       portMappings = [
#         {
#           containerPort = 7000
#         }
#       ]
#     },
#     {
#       name = "productcatalogservice"
#       image = "${aws_ecr_repository.watchtower_repository.repository_url}:product-latest"
#       essential = true
#       portMappings = [
#         {
#           containerPort = 3550
#         }
#       ]
#     },
#     {
#       name = "paymentservice"
#       image = "${aws_ecr_repository.watchtower_repository.repository_url}:payment-latest"
#       essential = true
#       portMappings = [
#         {
#           containerPort = 5000
#         }
#       ]
#     }
#   ])
# }


data "aws_ecs_task_definition" "task" {
  task_definition = "watchTower-task"
}

resource "aws_ecs_service" "watchTower_service" {
  name = "watchTower-ecs-service"
  cluster = aws_ecs_cluster.watchTower_cluster.id
  task_definition = data.aws_ecs_task_definition.task.arn
  desired_count = 1
  launch_type = "FARGATE"

  network_configuration {
    subnets = [for subnet in aws_subnet.watchtower_subnet : subnet.id]
    assign_public_ip = true
    security_groups = [aws_security_group.ecs_sg.id]
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.watchtower_tg.arn
    container_name = "frontend"
    container_port = 8080
  }
}