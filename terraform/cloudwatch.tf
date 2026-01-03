resource "aws_cloudwatch_log_group" "watchTower" {
   name = "/ecs/watchTower-log-group"
   retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "grafana" {
  name = "/ecs/grafana-log-group"
  retention_in_days = 14
}