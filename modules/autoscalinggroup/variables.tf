variable "tags" {
  description = "A map of tags and values in the same format as other resources accept. This will be converted into the non-standard format that the aws_autoscaling_group requires."
  type        = "map"
  default     = {}
}

# Small Lookup map to validate route53_record_type
variable "allowed_autoscalinggroup_types" {
  default = {
    LEGACY     = "LEGACY"
    AUTOUPDATE = "AUTOUPDATE"
    MIGRATION  = "MIGRATION"
  }
}

variable "autoscalinggroup_type" {}

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

variable "datadog_enabled" {
  description = "Is datadog enabled ? "
  default     = false
}

variable "datadog_api_key" {
  description = "Datadog API Key"
  default     = false
}

variable "environment" {
  description = "Which environment are we in ? For datadog"
  type        = "string"
}
