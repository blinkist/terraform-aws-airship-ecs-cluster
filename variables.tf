variable "name" {
  type        = string
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
  type        = string
  default     = ""
}

variable "ecs_instance_scaling_properties" {
  type    = list(map(string))
  default = []
}

variable "vpc_id" {
  description = "the main vpc identifier"
  type        = string
  default     = ""
}

variable "vpc_security_group_ids" {
  description = "List of VPC security groups to associate"
  type        = list(string)
  default     = []
}

variable "subnet_ids" {
  description = "the list of subnet_ids the autoscaling groups will use"
  type        = list(string)
  default     = []
}

variable "cluster_properties" {
  type = map(string)

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
  type    = map(string)
  default = {}
}

variable "iam_role_description" {
  description = "A description of the IAM Role of the instances, sometimes used by 3rd party sw"
  type        = string
  default     = ""
}
