locals {
  service_name = lookup(var.fargate_services, "service_name", "app")
}

resource "aws_ecs_service" "main" {
  name                               = lookup(var.fargate_services, "service_name", "app")
  cluster                            = var.cluster_id
  task_definition                    = lookup(var.fargate_services, "task_definition_arn")
  desired_count                      = lookup(var.fargate_services, "service_desired_count", 1)
  launch_type                        = "FARGATE"
  force_new_deployment               = var.force_new_deployment
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  deployment_maximum_percent         = var.deployment_maximum_percent

  enable_execute_command = true

  network_configuration {
    security_groups  = var.security_group_ids
    assign_public_ip = var.assign_public_ip
    subnets          = var.subnet_ids
  }

  dynamic "load_balancer" {
    for_each = var.fargate_services["lb_config"] == null ? [] : [for s in var.fargate_services["lb_config"] : {
      target_group_arn = s.target_group_arn != null ? s.target_group_arn : null
      container_name   = s.container_name != null ? s.container_name : null
      container_port   = s.container_port != null ? s.container_port : null
    }]

    content {
      target_group_arn = load_balancer.value.target_group_arn
      container_name   = load_balancer.value.container_name
      container_port   = load_balancer.value.container_port
    }
  }

  dynamic "lifecycle" {
    for_each = var.ignored_lifecycle_changes != [] ? [1] : []
    content {
      ignore_changes = var.ignored_lifecycle_changes
    }
  }
  
}

#------------------------------------------------------------------------------
# AWS Auto Scaling - CloudWatch Alarm CPU High
#------------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  count               = var.enable_autoscaling ? 1 : 0 
  alarm_name          = "${local.service_name}-cpu-hihg"
  alarm_description   = "ECS Fargate Service CPU utilization"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Maximum"
  threshold           = var.max_cpu_threshold
  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = local.service_name
  }
  alarm_actions = [aws_appautoscaling_policy.scale_up_policy.arn]
}

#------------------------------------------------------------------------------
# AWS Auto Scaling - CloudWatch Alarm CPU Low
#------------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_low" {
  count               = var.enable_autoscaling ? 1 : 0 
  alarm_name          = "${local.service_name}-cpu-low"
  alarm_description   = "ECS Fargate Service CPU utilization"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = var.min_cpu_threshold
  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = local.service_name
  }
  alarm_actions = [aws_appautoscaling_policy.scale_down_policy.arn]
}

#------------------------------------------------------------------------------
# AWS Auto Scaling - Scaling Up Policy
#------------------------------------------------------------------------------
resource "aws_appautoscaling_policy" "scale_up_policy" {
  name               = "${local.service_name}-scale-up-policy"
  depends_on         = [aws_appautoscaling_target.scale_target]
  service_namespace  = "ecs"
  resource_id        = "service/${var.cluster_name}/${local.service_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"
    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }
}

#------------------------------------------------------------------------------
# AWS Auto Scaling - Scaling Down Policy
#------------------------------------------------------------------------------
resource "aws_appautoscaling_policy" "scale_down_policy" {
  name               = "${local.service_name}-scale-down-policy"
  depends_on         = [aws_appautoscaling_target.scale_target]
  service_namespace  = "ecs"
  resource_id        = "service/${var.cluster_name}/${local.service_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"
    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }
}

#------------------------------------------------------------------------------
# AWS Auto Scaling - Scaling Target
#------------------------------------------------------------------------------
resource "aws_appautoscaling_target" "scale_target" {
  service_namespace  = "ecs"
  resource_id        = "service/${var.cluster_name}/${local.service_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.environment == "prd" ? var.scale_target_min_capacity : 1
  max_capacity       = var.environment == "prd" ? var.scale_target_max_capacity : 2
}