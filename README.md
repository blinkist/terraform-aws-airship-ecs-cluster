# AWS ECS Cluster Terraform Module [![Build Status](https://travis-ci.org/blinkist/terraform-aws-airship-ecs-cluster.svg?branch=master)](https://travis-ci.org/blinkist/terraform-aws-airship-ecs-cluster) [![Slack Community](https://slack.cloudposse.com/badge.svg)](https://slack.cloudposse.com)

## Introduction

This is a partner project to the [AWS ECS Service Terraform Module](https://github.com/blinkist/terraform-aws-airship-ecs-service/). This Terraform module provides a way to easily create and manage Amazon ECS clusters. It does not provide a Lambda function for draining, but it will need an ARN of a lambda in case scaling is enabled. The module will then create the lifecycle hook and permissions needed for automatic draining.

## Usage Full example, Scaling and EFS mounting enabled

A complete example can be found in the "examples/full" sub-folder.

## Usage without ECS Scaling and without EFS mounting

```hcl
module "ecs_web" {
  source  = "blinkist/airship-ecs-cluster/aws"
  version = "x.y.z" # TODO: Insert the latest version compatible with 0.12

  name = "${terraform.workspace}-web"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_properties {
    ec2_key_name      = aws_key_pair.main.key_name
    ec2_instance_type = "t2.small"
    ec2_asg_min       = 1
    ec2_asg_max       = 1
    ec2_disk_size     = 100
    ec2_disk_type     = "gp2"
  }

  vpc_security_group_ids = [module.ecs_instance_sg.this_security_group_id, module.admin_sg.this_security_group_id]

  tags= {
    Environment = terraform.workspace
  }
}
```

## Usage for Fargate

```hcl
module "ecs_fargate" {
  source  = "blinkist/airship-ecs-cluster/aws"
  version = "x.y.z" # TODO: Insert the latest version compatible with 0.12

  name = "${terraform.workspace}-web"

  create_roles                = false   # create IAM Roles for EC2 instances
  create_autoscalinggroup     = false   # create an ASG for ECS
}
```
