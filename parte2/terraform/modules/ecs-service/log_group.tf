resource "aws_cloudwatch_log_group" "ecs_service_logs" {
  name_prefix       = "/ecs/${local.service_id}"
  retention_in_days = 7
  tags              = var.tags
}