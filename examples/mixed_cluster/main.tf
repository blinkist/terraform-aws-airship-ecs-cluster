/**
 * # Mixed cluster
 * 
 * Creates a fixed size ECS cluster backed by a mixture of different instance types, both spot- and on demand instances.
 * 
 * The magic happens in the "enable_mixed_cluster", "mixed_cluster_instances_distribution", and "mixed_cluster_launch_template_override" parameters.
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

resource "aws_key_pair" "main" {
  key_name   = "deployer-key"
  public_key = "${var.public_key}"
}

module "ecs_web" {
  source = "../.."

  name                   = "${terraform.workspace}-web"               # re-used as a unique identifier for the creation of different resources
  vpc_id                 = "${data.aws_vpc.selected.id}"
  subnet_ids             = ["${data.aws_subnet.selected.id}"]
  vpc_security_group_ids = ["${data.aws_security_group.selected.id}"] # the security groups for the ec2 instances.

  cluster_properties = {
    ec2_key_name      = "${aws_key_pair.main.key_name}"
    ec2_instance_type = "t3.nano"                       # This is ignored when using mixed clusters ...

    # EC2
    ec2_asg_min   = 5     # the minimum size of the autoscaling group    
    ec2_asg_max   = 5     # the maximum size of the autoscaling group    
    ec2_disk_size = 100
    ec2_disk_type = "gp2"
  }

  enable_mixed_cluster = true

  mixed_cluster_instances_distribution = {
    on_demand_base_capacity                  = 1  # At least one on-demand instance
    on_demand_percentage_above_base_capacity = 25 # 25% of the instances above "on_demand_base_capacity" must be on-demand (should be one extra on-demand and three spot instances)
    spot_instance_pools                      = 2  # Number of Spot pools per availability zone to allocate capacity.
    spot_max_price                           = "" # Maximum price per unit hour that the user is willing to pay for the Spot instances. An empty string which means the on-demand price.
  }

  # Fill spot instances from the following list based on what is cheapest at the moment
  mixed_cluster_launch_template_override = [
    {
      instance_type = "t3.nano"
    },
    {
      instance_type = "t2.nano"
    },
    {
      instance_type = "t3.micro"
    },
    {
      instance_type = "t2.micro"
    },
    {
      instance_type = "t3.small"
    },
    {
      instance_type = "t2.small"
    },
  ]

  tags = {
    Environment = "${terraform.workspace}"
  }
}
