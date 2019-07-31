variable "name" {
  type        = "string"
  description = "the short name of the environment that is used to define it"
}

variable "create" {
  description = "Are we creating resources"
  default     = true
}

variable "create_roles" {
  description = "Are we creating iam roles"
  default     = true
}

variable "create_autoscalinggroup" {
  description = "Are we creating an autoscaling group"
  default     = true
}

variable "ecs_instance_scaling_create" {
  default     = false
  description = "Do we want to enable instance scaling for this ECS Cluster"
}

variable "ecs_instance_ebs_encryption" {
  default     = true
  description = "ecs_instance_ebs_encryption sets the Encryption property of the attached EBS Volumes"
}

variable "ecs_instance_draining_lambda_arn" {
  description = "The Lambda function arn taking care of the ECS Draining lifecycle"
  default     = ""
}

variable "ecs_instance_scaling_properties" {
  type    = "list"
  default = []
}

variable "vpc_id" {
  type        = "string"
  description = "the main vpc identifier"
  default     = ""
}

variable "vpc_security_group_ids" {
  description = "List of VPC security groups to associate"
  default     = []
}

variable "subnet_ids" {
  type        = "list"
  description = "the list of subnet_ids the autoscaling groups will use"
  default     = []
}

variable "cluster_properties" {
  type = "map"

  default = {
    create                 = false
    ec2_key_name           = ""
    ec2_instance_type      = "t2.small"
    ec2_asg_min            = 0
    ec2_asg_max            = 0
    ec2_disk_size          = 50
    ec2_disk_type          = "gp2"
    ec2_disk_encryption    = "false"
    ec2_custom_userdata    = ""
    block_metadata_service = false
    efs_enabled            = "0"
    efs_id                 = ""
  }
}

variable "tags" {
  type    = "map"
  default = {}
}

variable "iam_role_description" {
  type        = "string"
  description = "A description of the IAM Role of the instances, sometimes used by 3rd party sw"
  default     = ""
}

variable "enable_mixed_cluster" {
  description = "Create a mixed instance ASG, using the options from 'mixed_cluster_instances_distribution' and 'mixed_cluster_launch_template_override'"
  default     = false
}

variable "mixed_cluster_instances_distribution" {
  description = <<EOF
An object defining the on-demand vs. spot composition of a mixed cluster. 
See https://www.terraform.io/docs/providers/aws/r/autoscaling_group.html#mixed_instances_policy-instances_distribution"
EOF

  default = {
    on_demand_base_capacity                  = 0   # Absolute minimum amount of desired capacity that must be fulfilled by on-demand instances
    on_demand_percentage_above_base_capacity = 100 # Percentage split between on-demand and Spot instances above the base on-demand capacity.
    spot_instance_pools                      = 2   # Number of Spot pools per availability zone to allocate capacity. EC2 Auto Scaling selects the cheapest Spot pools and evenly allocates Spot capacity across the number of Spot pools that you specify.
    spot_max_price                           = ""  # Maximum price per unit hour that the user is willing to pay for the Spot instances. An empty string which means the on-demand price.
  }
}

variable "mixed_cluster_launch_template_override" {
  description = <<EOF
List of nested arguments provides the ability to specify multiple instance types. 
This will override the same parameter in the launch template. For on-demand instances, 
Auto Scaling considers the order of preference of instance types to launch based on 
the order specified in the overrides list. 
See https://www.terraform.io/docs/providers/aws/r/autoscaling_group.html#override"
EOF

  default = [
    {
      instance_type = "t2.small"
    },
    {
      instance_type = "t3.small"
    },
  ]
}

variable "enable_detailed_monitoring" {
  description = <<EOF
Data is available in 1-minute periods for an additional cost. To get this level of data, you must specifically enable it for the instance. 
For the instances where you've enabled detailed monitoring, you can also get aggregated data across groups of similar instances.
If 'false' data is collected in 5 minute intervals.
EOF

  default = false
}
