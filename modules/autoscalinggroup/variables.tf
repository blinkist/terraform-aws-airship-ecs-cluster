variable "tags" {
  description = "A map of tags and values in the same format as other resources accept. This will be converted into the non-standard format that the aws_autoscaling_group requires."
  type        = map(string)
  default     = {}
}

variable "create" {
  default = true
  type    = bool
}

variable "cluster_properties" {
  type = map(string)
}

variable "vpc_security_group_ids" {
  type = list(string)
}

variable "name" {
  description = "The description of the ASG"
  type        = string
}

variable "subnet_ids" {
  description = "The list of subnets where the ASG can reside"
  type        = list(string)
}

variable "iam_instance_profile" {
  description = "The IAM Profile of the autoscaling group instances"
  type        = string
}

variable "ami" {
  description = "The ami to use with the autoscaling group instances"
  default     = ""
  type        = string
}
