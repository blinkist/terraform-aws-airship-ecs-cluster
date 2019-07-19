variable "tags" {
  description = "A map of tags and values in the same format as other resources accept. This will be converted into the non-standard format that the aws_autoscaling_group requires."
  type        = "map"
  default     = {}
}

variable "create" {
  default = true
}

variable "cluster_properties" {
  type = "map"
}

variable "vpc_security_group_ids" {
  type = "list"
}

variable "name" {
  description = "The description of the ASG"
}

variable "subnet_ids" {
  description = "The list of subnets where the ASG can reside"
  type        = "list"
}

variable "iam_instance_profile" {
  description = "The IAM Profile of the autoscaling group instances"
}

variable "ami" {
  description = "The ami to use with the autoscaling group instances"
  default     = ""
}

variable "enable_mixed_cluster" {
  description = "If true, a mixed instance ASG is created, using the options from 'mixed_cluster_options'"
  default     = false
}

variable "mixed_cluster_instances_distribution" {
  description = "An object defining the on-demand vs. spot composition of a mixed cluster."
  type        = "map"
}

variable "mixed_cluster_launch_template_override" {
  description = "List of nested arguments provides the ability to specify multiple instance types."
  type        = "list"
}
