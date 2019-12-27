/* "Cloudwatch loggroup for the ECS-Agent" */
resource "aws_cloudwatch_log_group" "ecs" {
  count = var.create ? 1 : 0
  name  = "${var.name}/ecs-agent"
}

