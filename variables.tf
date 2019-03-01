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

variable "default_cluster_properties" {
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

    ## Because the autoscaling group automatically selects spot instances at the lowest price to create the cluster
    ## Put several types of spot instance types here
    ## https://docs.aws.amazon.com/autoscaling/ec2/APIReference/API_InstancesDistribution.html
    ec2_instance_type_override_1 = "m4.xlarge"

    ec2_instance_type_override_2 = "r4.xlarge"
    ec2_instance_type_override_3 = "r5.large"

    ## The percentage of ondemand instances to run in the cluster
    ## Set this to 100 to only use on_demand instances or to a value 
    ## between 1 and 100 to use a percentage of on_demand
    on_demand_base_capacity = "0"

    ## The extra capacity
    on_demand_percentage_above_base_capacity = "0"
  }
}

variable "cluster_properties" {
  type    = "map"
  default = {}
}

locals {
  cluster_properties = "${merge(var.default_cluster_properties, var.cluster_properties)}"
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
