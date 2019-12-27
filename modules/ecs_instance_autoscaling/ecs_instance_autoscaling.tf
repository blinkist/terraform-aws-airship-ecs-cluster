resource "aws_autoscaling_policy" "policy" {
  count = var.ecs_instance_scaling_create ? length(var.ecs_instance_scaling_properties) : 0
  name = "${var.asg_name}-${var.ecs_instance_scaling_properties[count.index]["type"]}-${element(
    var.direction[var.ecs_instance_scaling_properties[count.index]["direction"]],
    1,
  )}"
  scaling_adjustment     = var.ecs_instance_scaling_properties[count.index]["scaling_adjustment"]
  adjustment_type        = var.ecs_instance_scaling_properties[count.index]["adjustment_type"]
  cooldown               = var.ecs_instance_scaling_properties[count.index]["cooldown"]
  autoscaling_group_name = var.asg_name
}

resource "aws_cloudwatch_metric_alarm" "alarm" {
  count = var.ecs_instance_scaling_create ? length(var.ecs_instance_scaling_properties) : 0
  alarm_name = "${var.asg_name}-${var.ecs_instance_scaling_properties[count.index]["type"]}-${element(
    var.direction[var.ecs_instance_scaling_properties[count.index]["direction"]],
    1,
  )}"
  comparison_operator = element(
    var.direction[var.ecs_instance_scaling_properties[count.index]["direction"]],
    0,
  )
  evaluation_periods = var.ecs_instance_scaling_properties[count.index]["evaluation_periods"]
  metric_name        = var.ecs_instance_scaling_properties[count.index]["type"]
  namespace          = "AWS/ECS"
  period             = var.ecs_instance_scaling_properties[count.index]["observation_period"]
  statistic          = var.ecs_instance_scaling_properties[count.index]["statistic"]
  threshold          = var.ecs_instance_scaling_properties[count.index]["threshold"]

  dimensions = {
    ClusterName = var.cluster_name
  }

  alarm_actions = [aws_autoscaling_policy.policy[count.index].arn]
}

