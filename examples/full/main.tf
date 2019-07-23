/**
 * # Full example
 * 
 * Creates an ECS cluster backed by an autoscaling EC2 cluster with EFS mounting enabled.
 */

terraform {
  required_version = "~> 0.11.0"
}

provider "aws" {
  region                      = "${var.region}"
  skip_get_ec2_platforms      = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
  skip_credentials_validation = true
  version                     = "~> 2.20"
}

provider "null" {
  version = "~> 2.1"
}

provider "template" {
  version = "~> 2.1"
}

data "aws_vpc" "selected" {
  default = true
}

data "aws_availability_zones" "available" {}

data "aws_subnet" "selected" {
  availability_zone = "${data.aws_availability_zones.available.names[0]}"
  default_for_az    = true
  vpc_id            = "${data.aws_vpc.selected.id}"
}

data "aws_security_group" "selected" {
  name   = "default"
  vpc_id = "${data.aws_vpc.selected.id}"
}

module "efs" {
  source  = "cloudposse/efs/aws"
  version = "0.9.0"

  namespace  = "eg"
  stage      = "prod"
  name       = "app"
  attributes = ["efs"]

  aws_region         = "${var.region}"
  vpc_id             = "${data.aws_vpc.selected.id}"
  subnets            = ["${data.aws_subnet.selected.id}"]
  availability_zones = ["${data.aws_availability_zones.available.names[0]}"]
  security_groups    = ["${data.aws_security_group.selected.id}"]

  #zone_id = var.aws_route53_dns_zone_id
}

resource "aws_key_pair" "main" {
  key_name   = "deployer-key"
  public_key = "${var.public_key}"
}

# ECS Draining module will create a lambda function which takes care of instance draining.
module "ecs_draining" {
  source  = "blinkist/airship-ecs-instance-draining/aws"
  version = "0.1.0"
  name    = "web"
}

module "ecs_web" {
  source = "../.."

  name                   = "${terraform.workspace}-web"               # re-used as a unique identifier for the creation of different resources
  vpc_id                 = "${data.aws_vpc.selected.id}"
  subnet_ids             = ["${data.aws_subnet.selected.id}"]
  vpc_security_group_ids = ["${data.aws_security_group.selected.id}"] # the security groups for the ec2 instances.

  cluster_properties = {
    ec2_key_name      = "${aws_key_pair.main.key_name}" # ec2_key_name defines the keypair    
    ec2_instance_type = "t2.small"                      # ec2_instance_type defines the instance type

    # EC2
    ec2_asg_min            = 1     # the minimum size of the autoscaling group    
    ec2_asg_max            = 1     # the maximum size of the autoscaling group    
    ec2_disk_size          = 100   # the size in GB of the non-root volume of the EC2 Instance    
    ec2_disk_type          = "gp2" # the disktype of that EBS Volume
    block_metadata_service = true  # block the aws metadata service from the ECS Tasks. This is preferred security wise

    # EFS
    efs_enabled      = true               # should EFS be mounted
    efs_id           = "${module.efs.id}" # the id of the EFS volume to mount
    efs_mount_folder = "/mnt/efs"         # the folder to which the EFS volume will be mounted
  }

  # NB! NB! A draining lambda ARN needs to be defined !!
  ecs_instance_scaling_create      = true                                         # set autscaling for the autoscaling group if true
  ecs_instance_draining_lambda_arn = "${module.ecs_draining.lambda_function_arn}" # The lambda function which takes care of draining the ecs instance

  # ecs_instance_scaling_properties defines how the ECS Cluster scales up / down
  ecs_instance_scaling_properties = [
    {
      type               = "MemoryReservation"
      direction          = "up"
      evaluation_periods = 2
      observation_period = 300
      statistic          = "Average"
      threshold          = 50
      cooldown           = 900
      adjustment_type    = "ChangeInCapacity"
      scaling_adjustment = 1
    },
    {
      type               = "MemoryReservation"
      direction          = "down"
      evaluation_periods = 4
      observation_period = 300
      statistic          = "Average"
      threshold          = 10
      cooldown           = 300
      adjustment_type    = "ChangeInCapacity"
      scaling_adjustment = -1
    },
  ]

  tags = {
    Environment = "${terraform.workspace}"
  }
}
