variable "ecs_instance_scaling_create" {
  type        = bool
  default     = false
  description = "Do we want to enable instance scaling for this ECS Cluster"
}

variable "ecs_instance_draining_lambda_arn" {
  type        = string
  default     = ""
  description = "The Lambda function arn taking care of the ECS Draining lifecycle"
}

variable "asg_name" {
  type        = string
  description = "The name of the Autoscaling group to scale"
}

variable "cluster_name" {
  type        = string
  description = "The name of the ECS Cluster"
}

variable "ecs_instance_scaling_properties" {
  type = list(map(string))
}

variable "direction" {
  type = map(list(string))

  default = {
    up   = ["GreaterThanOrEqualToThreshold", "scale_out"]
    down = ["LessThanThreshold", "scale_in"]
  }
}

