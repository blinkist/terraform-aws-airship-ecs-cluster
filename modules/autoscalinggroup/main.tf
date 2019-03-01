data "aws_region" "_" {}

locals {
  tags_asg_format = ["${null_resource.tags_as_list_of_maps.*.triggers}"]
  name            = "${var.name}"
  ami_id          = "${var.ami == "" ? join("", data.aws_ami.ecs_ami.*.id) : var.ami }"
}

resource "null_resource" "tags_as_list_of_maps" {
  count = "${(var.create ? 1 : 0 ) * length(keys(var.tags))}"

  triggers = "${map(
    "key", "${element(keys(var.tags), count.index)}",
    "value", "${element(values(var.tags), count.index)}",
    "propagate_at_launch", "false"
  )}"
}

## This creates a dependancy for the launmch template
resource "null_resource" "instance_profile" {
  triggers {
    instance_profile = "${var.iam_instance_profile}"
  }
}

data "template_file" "cloud_config_amazon" {
  template = "${file("${path.module}/amazon_ecs_ami.sh")}"

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

resource "aws_launch_template" "default" {
  count                                = "${var.create ? 1 : 0 }"
  name                                 = "${local.name}-container-instance"
  image_id                             = "${local.ami_id}"
  instance_initiated_shutdown_behavior = "terminate"
  instance_type                        = "${lookup(var.cluster_properties, "ec2_instance_type")}"
  key_name                             = "${lookup(var.cluster_properties, "ec2_key_name")}"
  ebs_optimized                        = "${lookup(var.cluster_properties, "ebs_optimized", "false")}"
  depends_on                           = ["null_resource.instance_profile"]
  user_data                            = "${base64encode(data.template_file.cloud_config_amazon.rendered)}"
  tags                                 = "${var.tags}"

  capacity_reservation_specification {
    capacity_reservation_preference = "open"
  }

  iam_instance_profile {
    arn = "${var.iam_instance_profile}"
  }

  monitoring {
    enabled = "${lookup(var.cluster_properties, "monitoring", "false")}"
  }

  tag_specifications {
    resource_type = "instance"
    tags          = "${var.tags}"
  }

  tag_specifications {
    resource_type = "volume"
    tags          = "${var.tags}"
  }

  ## Move up
  network_interfaces {
    associate_public_ip_address = "${lookup(var.cluster_properties, "associate_public_ip_address", "false")}"
    description                 = "${local.name}"
    security_groups             = ["${var.vpc_security_group_ids}"]
    delete_on_termination       = "true"
  }

  block_device_mappings {
    device_name = "/dev/xvdcz"

    ebs {
      volume_size           = "${lookup(var.cluster_properties, "ec2_disk_size", "40")}"
      volume_type           = "${lookup(var.cluster_properties, "ec2_disk_type", "gp2")}"
      delete_on_termination = "true"
      encrypted             = "${lookup(var.cluster_properties, "ec2_disk_encryption","true")}"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "this" {
  count           = "${var.create ? 1 : 0 }"
  name            = "${format("%v-%v",aws_launch_template.default.name, aws_launch_template.default.latest_version)}"
  min_size        = "${lookup(var.cluster_properties, "ec2_asg_min")}"
  max_size        = "${lookup(var.cluster_properties, "ec2_asg_max")}"
  placement_group = "${var.placement_group}"

  mixed_instances_policy {
    instances_distribution {
      on_demand_allocation_strategy            = "prioritized"
      on_demand_base_capacity                  = "${lookup(var.cluster_properties, "on_demand_base_capacity", "0")}"
      on_demand_percentage_above_base_capacity = "${lookup(var.cluster_properties, "on_demand_percentage_above_base_capacity", "0")}"
      spot_allocation_strategy                 = "lowest-price"
    }

    launch_template {
      launch_template_specification {
        launch_template_id = "${aws_launch_template.default.id}"
        version            = "$Latest"
      }

      override {
        instance_type = "${lookup(var.cluster_properties, "ec2_instance_type_override_1", "m4.xlarge")}"
      }

      override {
        instance_type = "${lookup(var.cluster_properties, "ec2_instance_type_override_2", "r4.large")}"
      }

      override {
        instance_type = "${lookup(var.cluster_properties, "ec2_instance_type_override_3", "i4.large")}"
      }
    }
  }

  vpc_zone_identifier = [
    "${var.subnet_ids}",
  ]

  lifecycle {
    create_before_destroy = true
  }

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances",
  ]

  tags = ["${concat(
      list(map("key", "Name", "value", local.name, "propagate_at_launch", false)),
      local.tags_asg_format
   )}"]
}
