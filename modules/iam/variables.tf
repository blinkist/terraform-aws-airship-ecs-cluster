variable "name" {
  type        = string
  description = "A preferably short unique identifier for this module"
}

variable "iam_role_description" {
  type        = string
  description = "A description of the IAM Role of the instances, sometimes used by 3rd party sw"
}

variable "create" {
  default     = true
  description = "Whether to create everything related"
}

