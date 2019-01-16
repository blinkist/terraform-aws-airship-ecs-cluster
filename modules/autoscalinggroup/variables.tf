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
}
