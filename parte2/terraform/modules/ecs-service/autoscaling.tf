resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = var.scale.max
  min_capacity       = var.scale.min
  resource_id        = "service/${data.aws_ecs_cluster.cluster.cluster_name}/${aws_ecs_service.application.name}"
  role_arn           = data.aws_iam_role.ecs_task_execution_role.arn
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_policy" {
  name               = "${local.service_id}-autoscale"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value       = var.scale.cpu
    scale_in_cooldown  = "180" # seconds
    scale_out_cooldown = "60"  # seconds
  }
}
