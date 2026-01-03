resource "aws_security_group" "grafana_sg" {
    name = "grafana_security_group"
    vpc_id = aws_vpc.watchtower.id

    ingress {
        from_port = 3000
        to_port = 3000
        protocol = "tcp"
        security_groups = [aws_security_group.alb_sg.id]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Allow all outbound traffi"
    }
}

data "aws_ecs_task_definition" "grafana_task_def" {
  task_definition = "grafana-task"
}

# resource "aws_ecs_task_definition" "grafana_task" {
#   family = "grafana_task_def"
#   network_mode = "awsvpc"
#   requires_compatibilities = [ "FARGATE"]
#   cpu = 256
#   memory = 512
#   execution_role_arn = aws_iam_role.ecs_execution_role.arn
#   container_definitions = jsonencode([
#     {
#         name = "grafana",
#         image = "grafana/grafana:latest",
#         essential = true
#         portMappings = [
#             {
#                 containerPort = 3000
#                 protocol = "tcp"
#             }
#         ],
#     }
#   ])
# }

resource "aws_ecs_service" "grafana_service" {
  name = "grafana-ecs-service"
  cluster = aws_ecs_cluster.watchTower_cluster.id
  task_definition = data.aws_ecs_task_definition.grafana_task_def
  desired_count = 1
  launch_type = "FARGATE"

  network_configuration {
    subnets = [for subnet in aws_subnet.watchtower_subnet : subnet.id]
    assign_public_ip = true
    security_groups = [aws_security_group.grafana_sg.id]
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.grafana_tg.arn
    container_name = "grafana"
    container_port = 3000
  }
}
