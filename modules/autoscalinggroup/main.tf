data "aws_region" "_" {}

locals {
  tags_asg_format = ["${null_resource.tags_as_list_of_maps.*.triggers}"]
  name            = "${var.name}"
}

resource "null_resource" "tags_as_list_of_maps" {
  count = "${(var.create ? 1 : 0 ) * length(keys(var.tags))}"

  triggers = "${map(
    "key", "${element(keys(var.tags), count.index)}",
    "value", "${element(values(var.tags), count.index)}",
    "propagate_at_launch", "true"
  )}"
}

data "template_file" "cloud_config_amazon" {
  template = "${file("${path.module}/amazon_ecs_ami.yml")}"

  vars {
    region                 = "${data.aws_region._.name}"
    name                   = "${local.name}"
    block_metadata_service = "${lookup(var.cluster_properties, "block_metadata_service", "0")}"
    efs_enabled            = "${lookup(var.cluster_properties, "efs_enabled", "0")}"
    efs_id                 = "${lookup(var.cluster_properties, "efs_id","")}"
    efs_mount_folder       = "${lookup(var.cluster_properties, "efs_mount_folder","/mnt/efs")}"
    custom_userdata        = "${lookup(var.cluster_properties, "ec2_custom_userdata","")}"
  }
}

resource "aws_launch_template" "launch_template" {
  count = "${var.create ? 1 : 0 }"

  name_prefix            = "${local.name}-"
  description            = "Template for EC2 instances used by ECS"
  image_id               = "${data.aws_ami.ecs_ami.id}"
  instance_type          = "${lookup(var.cluster_properties, "ec2_instance_type")}"
  key_name               = "${lookup(var.cluster_properties, "ec2_key_name")}"
  vpc_security_group_ids = ["${var.vpc_security_group_ids}"]
  user_data              = "${base64encode(data.template_file.cloud_config_amazon.rendered)}"

  iam_instance_profile = {
    arn = "${var.iam_instance_profile}"
  }

  monitoring {
    enabled = "${var.enable_detailed_monitoring}"
  }

  block_device_mappings = [
    {
      device_name = "/dev/xvda"

      ebs = {
        volume_size           = "15"
        volume_type           = "gp2"
        delete_on_termination = true
      }
    },
    {
      device_name = "/dev/xvdcz"

      ebs = {
        volume_size           = "${lookup(var.cluster_properties, "ec2_disk_size")}"
        volume_type           = "${lookup(var.cluster_properties, "ec2_disk_type")}"
        delete_on_termination = true
        encrypted             = "${lookup(var.cluster_properties, "ec2_disk_encryption","true")}"
      }
    },
  ]

  lifecycle {
    create_before_destroy = true
  }
}

locals {
  asg_enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances",
  ]

  asg_tags = ["${concat(
      list(map("key", "Name", "value", local.name, "propagate_at_launch", true)),
      local.tags_asg_format
   )}"]
}

# An ASG where every node is identical
resource "aws_autoscaling_group" "homogenous" {
  count = "${var.create && !var.enable_mixed_cluster ? 1 : 0 }"
  name  = "${local.name}"

  launch_template = {
    id      = "${aws_launch_template.launch_template.id}"
    version = "$Latest"
  }

  min_size            = "${lookup(var.cluster_properties, "ec2_asg_min")}"
  max_size            = "${lookup(var.cluster_properties, "ec2_asg_max")}"
  placement_group     = "${lookup(var.cluster_properties, "ec2_placement_group", "")}"
  vpc_zone_identifier = ["${var.subnet_ids}"]
  enabled_metrics     = ["${local.asg_enabled_metrics}"]
  tags                = ["${local.asg_tags}"]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "heterogenous" {
  count = "${var.create && var.enable_mixed_cluster ? 1 : 0 }"
  name  = "${local.name}"

  #name  = "dummy"

  mixed_instances_policy = {
    instances_distribution = ["${var.mixed_cluster_instances_distribution}"]

    launch_template {
      launch_template_specification {
        launch_template_id = "${aws_launch_template.launch_template.id}"
        version            = "$Latest"
      }

      override = ["${var.mixed_cluster_launch_template_override}"]
    }
  }
  min_size            = "${lookup(var.cluster_properties, "ec2_asg_min")}"
  max_size            = "${lookup(var.cluster_properties, "ec2_asg_max")}"
  placement_group     = "${lookup(var.cluster_properties, "ec2_placement_group", "")}"
  vpc_zone_identifier = ["${var.subnet_ids}"]
  enabled_metrics     = ["${local.asg_enabled_metrics}"]
  tags                = ["${local.asg_tags}"]
  lifecycle {
    create_before_destroy = true
  }
}
