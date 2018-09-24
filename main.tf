#
# iam module creates the necessary IAM roles for running an ECS Cluster
#
module "iam" {
  source = "./modules/iam/"

  iam_role_description = "${var.iam_role_description}"

  # name is used to create unique rolenames per ecs cluster
  name = "${var.name}"

  # default to true, when false no roles are created
  create = "${var.create_roles && var.create}"
}

# 
# The actual ECS Cluster  
#
resource "aws_ecs_cluster" "this" {
  count = "${var.create ? 1 : 0 }"

  name = "${var.name}"

  lifecycle {
    create_before_destroy = true
  }
}

#
# autoscalinggroup delivers the Autoscaling group with EC2 Instances
#
module "autoscalinggroup" {
  source                 = "./modules/autoscalinggroup/"
  create                 = "${var.create_autoscalinggroup && var.create}"
  name                   = "${var.name}"
  autoscalinggroup_type  = "${var.autoscalinggroup_type}"
  cluster_properties     = "${var.cluster_properties}"
  vpc_security_group_ids = ["${var.vpc_security_group_ids}"]
  iam_instance_profile   = "${module.iam.ecs_instance_profile}"
  tags                   = "${var.tags}"
  subnet_ids             = ["${var.subnet_ids}"]
  environment            = "${var.environment}"
}

#
# ecs_instance_scaling takes care of proper Autoscaling
#
module "ecs_instance_scaling" {
  source                           = "./modules/ecs_instance_autoscaling/"
  ecs_instance_scaling_create      = "${var.ecs_instance_scaling_create && var.create && var.autoscalinggroup_type != "MIGRATION"}"
  asg_name                         = "${module.autoscalinggroup.asg_name}"
  cluster_name                     = "${var.name}"
  ecs_instance_draining_lambda_arn = "${var.ecs_instance_draining_lambda_arn}"
  ecs_instance_scaling_properties  = ["${var.ecs_instance_scaling_properties}"]
}

#
# Datadog ECS Service
#
module "datadog" {
  source          = "./modules/datadog/"
  create          = "${var.datadog_enabled && var.create}"
  name            = "${var.name}"
  cluster_id      = "${aws_ecs_cluster.this.id}"
  datadog_enabled = "${var.datadog_enabled}"
  datadog_api_key = "${var.datadog_api_key}"
  environment     = "${var.environment}"
}
