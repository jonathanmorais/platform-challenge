resource "aws_lb_target_group" "alb_tg" {
  count                = var.alb.enable ? 1 : 0
  name                 = local.service_id
  port                 = var.container.port
  protocol             = "HTTP"
  target_type          = "ip"
  vpc_id               = var.network.vpc
  deregistration_delay = var.tg.deregistration_delay

  health_check {
    path                = var.tg.health_check_path
    protocol            = "HTTP"
    port                = "traffic-port"
    healthy_threshold   = var.tg.health_check_healthy_threshold
    unhealthy_threshold = var.tg.health_check_unhealthy_threshold
    timeout             = var.tg.health_check_timeout
    interval            = var.tg.interval
    matcher             = "200"
  }

  lifecycle {
      create_before_destroy = true
      ignore_changes        = [name]
    }
}

resource "aws_lb" "alb" {
  count                      = var.alb.enable ? 1 : 0
  name                       = local.service_id
  internal                   = ! var.alb.public
  load_balancer_type         = "application"
  security_groups            = var.alb.security_groups
  subnets                    = var.alb.subnets
  enable_deletion_protection = var.alb.enable_deletion_protection
  tags                       = var.tags
  idle_timeout               = var.alb.idle_timeout

}

resource "aws_lb_listener" "alb_listener_http" {
  count             = var.alb.enable ? 1 : 0
  load_balancer_arn = aws_lb.alb[count.index].arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_tg[count.index].arn
  }

  depends_on = [aws_lb.alb, aws_lb_target_group.alb_tg]
}

data "aws_acm_certificate" "acm_certificate" {
  count = var.alb.enable && var.alb.certificate_domain != "" ? 1 : 0
  domain      = var.alb.certificate_domain
  statuses    = ["ISSUED"]
  most_recent = true
}

resource "aws_alb_listener" "alb_listener_https" {
  count             = var.alb.enable && var.alb.certificate_domain != "" ? 1 : 0
  load_balancer_arn = aws_lb.alb[count.index].arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.acm_certificate[count.index].arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_tg[count.index].arn
  }
  depends_on = [aws_lb.alb, aws_lb_target_group.alb_tg]
}

resource "aws_lb_listener_rule" "redirect_http_to_https" {
  count        = var.alb.redirect_to_https && var.alb.enable && var.alb.certificate_domain != "" ? 1 : 0
  listener_arn = aws_lb_listener.alb_listener_http[count.index].arn

  action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }
}