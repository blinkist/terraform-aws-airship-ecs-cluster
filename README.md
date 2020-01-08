# AWS ECS Cluster Terraform Module [![Build Status](https://travis-ci.org/blinkist/terraform-aws-airship-ecs-cluster.svg?branch=master)](https://travis-ci.org/blinkist/terraform-aws-airship-ecs-cluster) [![Slack Community](https://slack.cloudposse.com/badge.svg)](https://slack.cloudposse.com)

## Introduction

 _**NOTE**: Major version 1 will be used for Terraform 0.12, while major version 0 is used for Terraform version 0.11._

This is a partner project to the [AWS ECS Service Terraform Module](https://github.com/blinkist/terraform-aws-airship-ecs-service/). This Terraform module provides a way to easily create and manage Amazon ECS clusters. It does not provide a Lambda function for draining, but it will need an ARN of a lambda in case scaling is enabled. The module will then create the lifecycle hook and permissions needed for automatic draining.

## Usage Full example, Scaling and EFS mounting enabled

```hcl
# ECS Draining module will create a lambda function which takes care of instance draining.
module "ecs_draining {
  source  = "blinkist/airship-ecs-instance-draining/aws"
  version = "0.1.0"
  name = "web"
}

# Example of extra userdata, to be added to the instance inside the ASG
data "template_file" "extra_userdata" {
  template = "${file("${path.module}/extrauserdata.yml")}"

  vars {
    ssh_pub_key = "${var.some_ssh_key}"
  }
}

module "ecs_web" { 
  source  = "blinkist/airship-ecs-cluster/aws"
  version = "0.5.0"

  # name is re-used as a unique identifier for the creation of different resources
  name            = "${terraform.workspace}-web"

  vpc_id          = "${module.vpc.vpc_id}"
  subnet_ids      = ["${module.vpc.private_subnets}"]

  cluster_properties {
    # ec2_key_name defines the keypair
    ec2_key_name = "${aws_key_pair.main.key_name}"
    # ec2_instance_type defines the instance type
    ec2_instance_type = "t2.small"
    # ec2_custom_userdata sets the launch configuration userdata for the EC2 instances
    ec2_custom_userdata = "${data.template_file.extra_userdata.rendered}"
    # ec2_asg_min defines the minimum size of the autoscaling group
    ec2_asg_min = "1"
    # ec2_asg_max defines the maximum size of the autoscaling group
    ec2_asg_max = "1"
    # ec2_disk_size defines the size in GB of the non-root volume of the EC2 Instance
    ec2_disk_size = "100"
    # ec2_disk_type defines the disktype of that EBS Volume
    ec2_disk_type = "gp2"
    # ec2_disk_encryption = "true"

    # block_metadata_service blocks the aws metadata service from the ECS Tasks true / false, this is preferred security wise
    block_metadata_service = true

    # efs_enabled sets if EFS should be mounted
    efs_enabled = true
    # the id of the EFS volume to mount
    efs_id = "${module.efs.aws_efs_file_system_sharedfs_id}"
    # efs_mount_folder defines the folder to which the EFS volume will be mounted
    # efs_mount_folder = "/mnt/efs"
  }
  
  # vpc_security_group_ids defines the security groups for the ec2 instances.
  vpc_security_group_ids = ["${module.ecs_instance_sg.this_security_group_id}","${module.admin_sg.this_security_group_id}"]

  # ecs_instance_scaling_create defines if we set autscaling for the autoscaling group
  # NB! NB! A draining lambda ARN needs to be defined !!
  ecs_instance_scaling_create = true

  # The lambda function which takes care of draining the ecs instance
  ecs_instance_draining_lambda_arn = "${module.ecs_draining.lambda_function_arn}"

  # ecs_instance_scaling_properties defines how the ECS Cluster scales up / down
  ecs_instance_scaling_properties = [
   { 
     type = "MemoryReservation"
     direction = "up"
     evaluation_periods = 2
     observation_period = "300"
     statistic = "Average"
     threshold = "50"
     cooldown = "900"
     adjustment_type = "ChangeInCapacity"
     scaling_adjustment = "1"
   },
   { 
     type = "MemoryReservation"
     direction = "down"
     evaluation_periods = 4
     observation_period = "300"
     statistic = "Average"
     threshold = "10"
     cooldown = "300"
     adjustment_type = "ChangeInCapacity"
     scaling_adjustment = "-1"
   },
  ]

  tags = { 
	Environment = "${terraform.workspace}"
  }
}
```

## Usage without ECS Scaling and without EFS mounting
```hcl
module "ecs_web" { 
  source  = "blinkist/airship-ecs-cluster/aws"
  version = "0.5.0"

  name            = "${terraform.workspace}-web"

  vpc_id          = "${module.vpc.vpc_id}"
  subnet_ids      = ["${module.vpc.private_subnets}"]

  cluster_properties {
    ec2_key_name = "${aws_key_pair.main.key_name}"
    ec2_instance_type = "t2.small"
    ec2_asg_min = "1"
    ec2_asg_max = "1"
    ec2_disk_size = "100"
    ec2_disk_type = "gp2"
  }
  
  vpc_security_group_ids = ["${module.ecs_instance_sg.this_security_group_id}","${module.admin_sg.this_security_group_id}"]

  tags= { 
	Environment = "${terraform.workspace}"
  }
}
```

## Usage for Fargate
```hcl
module "ecs_fargate" { 
  source  = "blinkist/airship-ecs-cluster/aws"
  version = "0.5.0"

  name = "${terraform.workspace}-web"

  # create_roles defines if we create IAM Roles for EC2 instances
  create_roles                    = false
  # create_autoscalinggroup defines if we create an ASG for ECS
  create_autoscalinggroup         = false
  # ecs_instance_scaling_create     = false

}
```
