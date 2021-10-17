data aws_ecs_cluster "cluster" {
  cluster_name = var.cluster
}


resource "aws_ecs_service" "application" {
  name                              = local.service_id
  desired_count                     = var.scale.min
  cluster                           = data.aws_ecs_cluster.cluster.arn
  task_definition                   = aws_ecs_task_definition.service.arn
  enable_ecs_managed_tags           = true
  propagate_tags                    = "SERVICE"
  health_check_grace_period_seconds = var.container.health_check_grace_period_seconds

  network_configuration {
    subnets         = var.network.subnets
    security_groups = var.network.security_groups
  }

  dynamic "load_balancer" {
     for_each = var.alb.enable == true ? [1] : []
    content {
      target_group_arn = aws_lb_target_group.alb_tg[0].arn
      container_name   = local.service_id
      container_port   = var.container.port
    }
  }

  capacity_provider_strategy {
    capacity_provider = var.capacity_provider
    weight = 1
  }

  depends_on = [
    aws_lb_listener.alb_listener_http,
  aws_ecs_task_definition.service]

  lifecycle {
    // create an ECS service with an initial count of running instances,
    // then ignore any changes to that count caused externally (e.g. Application Autoscaling).
    ignore_changes = [desired_count]
  }

  tags = var.tags
}