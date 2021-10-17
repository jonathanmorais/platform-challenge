data "template_file" "ecs_task_definition" {
  template = file("${path.module}/task-definitions/service.tpl.json")

  vars = {
    log_group   = aws_cloudwatch_log_group.ecs_service_logs.name
    service_id  = local.service_id
    image       = var.container.image
    cpu         = var.container.cpu
    memory      = var.container.memory
    port        = var.container.port
    environment = jsonencode(var.environment)
    command     = jsonencode(var.command)
  }
}

resource "aws_ecs_task_definition" "service" {
  family                = local.service_id
  container_definitions = data.template_file.ecs_task_definition.rendered
  cpu                   = var.container.cpu
  memory                = var.container.memory
  network_mode          = "awsvpc"
  task_role_arn         = aws_iam_role.service.arn
  execution_role_arn    = data.aws_iam_role.ecs_task_execution_role.arn
  tags                  = var.tags

  depends_on = [
  aws_iam_role.service]
}