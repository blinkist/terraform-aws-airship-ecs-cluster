data "aws_region" "_" {
}

locals {
  tags_asg_format = null_resource.tags_as_list_of_maps.*.triggers
  name            = var.name
}

resource "null_resource" "tags_as_list_of_maps" {
  count = (var.create ? 1 : 0) * length(keys(var.tags))

  triggers = {
    "key"                 = element(keys(var.tags), count.index)
    "value"               = element(values(var.tags), count.index)
    "propagate_at_launch" = "true"
  }
}

data "template_file" "cloud_config_amazon" {
  template = file("${path.module}/amazon_ecs_ami.yml")

  vars = {
    region                 = data.aws_region._.name
    name                   = local.name
    block_metadata_service = lookup(var.cluster_properties, "block_metadata_service", "0")
    efs_enabled            = lookup(var.cluster_properties, "efs_enabled", "0")
    efs_id                 = lookup(var.cluster_properties, "efs_id", "")
    efs_mount_folder       = lookup(var.cluster_properties, "efs_mount_folder", "/mnt/efs")
    custom_userdata        = lookup(var.cluster_properties, "ec2_custom_userdata", "")
  }
}

resource "aws_launch_template" "launch_template" {
  count = var.create ? 1 : 0

  name_prefix            = "${local.name}-"
  description            = "Template for EC2 instances used by ECS"
  image_id               = data.aws_ami.ecs_ami.id
  instance_type          = var.cluster_properties["ec2_instance_type"]
  key_name               = var.cluster_properties["ec2_key_name"]
  vpc_security_group_ids = var.vpc_security_group_ids
  user_data              = base64encode(data.template_file.cloud_config_amazon.rendered)

  iam_instance_profile {
    arn = var.iam_instance_profile
  }

  monitoring {
    enabled = var.enable_detailed_monitoring
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = "15"
      volume_type           = "gp2"
      delete_on_termination = true
    }
  }

  block_device_mappings {
    device_name = "/dev/xvdcz"

    ebs {
      volume_size           = var.cluster_properties["ec2_disk_size"]
      volume_type           = var.cluster_properties["ec2_disk_type"]
      delete_on_termination = true
      encrypted             = lookup(var.cluster_properties, "ec2_disk_encryption", "true")
    }
  }

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

  asg_tags = concat(
    [
      {
        key                 = "Name"
        value               = local.name
        propagate_at_launch = true
      },
    ],
    local.tags_asg_format,
  )

}

# An ASG where every node is identical
resource "aws_autoscaling_group" "homogenous" {
  count = var.create && false == var.enable_mixed_cluster ? 1 : 0
  name  = local.name

  launch_template {
    id      = aws_launch_template.launch_template[0].id
    version = "$Latest"
  }

  min_size            = var.cluster_properties["ec2_asg_min"]
  max_size            = var.cluster_properties["ec2_asg_max"]
  placement_group     = lookup(var.cluster_properties, "ec2_placement_group", "")
  vpc_zone_identifier = var.subnet_ids
  enabled_metrics     = local.asg_enabled_metrics
  tags                = local.asg_tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "heterogenous" {
  count = var.create && var.enable_mixed_cluster ? 1 : 0
  name  = local.name

  mixed_instances_policy {
    dynamic "instances_distribution" {
      for_each = [var.mixed_cluster_instances_distribution]
      content {
        on_demand_allocation_strategy            = lookup(instances_distribution.value, "on_demand_allocation_strategy", null)
        on_demand_base_capacity                  = lookup(instances_distribution.value, "on_demand_base_capacity", null)
        on_demand_percentage_above_base_capacity = lookup(instances_distribution.value, "on_demand_percentage_above_base_capacity", null)
        spot_allocation_strategy                 = lookup(instances_distribution.value, "spot_allocation_strategy", null)
        spot_instance_pools                      = lookup(instances_distribution.value, "spot_instance_pools", null)
        spot_max_price                           = lookup(instances_distribution.value, "spot_max_price", null)
      }
    }

    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.launch_template[0].id
        version            = "$Latest"
      }

      dynamic "override" {
        for_each = var.mixed_cluster_launch_template_override
        content {
          instance_type     = lookup(override.value, "instance_type", null)
          weighted_capacity = lookup(override.value, "weighted_capacity", null)
        }
      }
    }
  }
  min_size            = var.cluster_properties["ec2_asg_min"]
  max_size            = var.cluster_properties["ec2_asg_max"]
  placement_group     = lookup(var.cluster_properties, "ec2_placement_group", "")
  vpc_zone_identifier = var.subnet_ids
  enabled_metrics     = local.asg_enabled_metrics
  tags                = local.asg_tags

  lifecycle {
    create_before_destroy = true
  }
}

