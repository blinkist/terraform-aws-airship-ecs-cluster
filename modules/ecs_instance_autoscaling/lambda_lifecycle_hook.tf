resource "aws_sns_topic" "asg_lifecycle" {
  count = var.ecs_instance_scaling_create ? 1 : 0
  name  = "${var.asg_name}-asg-lifecycle"
}

resource "aws_autoscaling_notification" "scale_notifications" {
  count = var.ecs_instance_scaling_create ? 1 : 0

  group_names = [
    var.asg_name,
  ]

  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
  ]

  topic_arn = aws_sns_topic.asg_lifecycle[0].arn
}

resource "aws_autoscaling_lifecycle_hook" "scale_hook" {
  count                   = var.ecs_instance_scaling_create ? 1 : 0
  name                    = "${var.asg_name}-scale-hook"
  autoscaling_group_name  = var.asg_name
  default_result          = "ABANDON"
  heartbeat_timeout       = 900
  lifecycle_transition    = "autoscaling:EC2_INSTANCE_TERMINATING"
  notification_target_arn = aws_sns_topic.asg_lifecycle[0].arn
  role_arn                = aws_iam_role.asg_publish_to_sns[0].arn
}

resource "aws_iam_role" "asg_publish_to_sns" {
  count = var.ecs_instance_scaling_create ? 1 : 0
  name  = "${var.asg_name}-asg-publish-to-sns"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [ {
    "Sid": "",
    "Effect": "Allow",
    "Principal": {
      "Service": "autoscaling.amazonaws.com"
    },
    "Action": "sts:AssumeRole"
  } ]
}
EOF

}

data "template_file" "asg_publish_to_sns" {
  count = var.ecs_instance_scaling_create ? 1 : 0

  vars = {
    topic_arn = aws_sns_topic.asg_lifecycle[0].arn
  }

  template = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Resource": "$${topic_arn}",
      "Action": [
        "sns:Publish"
      ]
    }
  ]
}
EOF

}

resource "aws_iam_role_policy" "asg_publish_to_sns" {
  count  = var.ecs_instance_scaling_create ? 1 : 0
  name   = "${var.asg_name}-asg-publish-to-sns"
  role   = aws_iam_role.asg_publish_to_sns[0].name
  policy = data.template_file.asg_publish_to_sns[0].rendered
}

resource "aws_lambda_permission" "drain_lambda" {
  count         = var.ecs_instance_scaling_create ? 1 : 0
  statement_id  = "AllowExecutionFromSNS-${var.cluster_name}"
  action        = "lambda:InvokeFunction"
  function_name = var.ecs_instance_draining_lambda_arn
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.asg_lifecycle[0].arn
}

resource "aws_sns_topic_subscription" "lambda" {
  count     = var.ecs_instance_scaling_create ? 1 : 0
  topic_arn = aws_sns_topic.asg_lifecycle[0].arn
  protocol  = "lambda"
  endpoint  = var.ecs_instance_draining_lambda_arn
}

