variable "public_key" {
  description = "The public key for the SSH key needed to SSH to the EC2 instances in the ECS cluster"
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAACEApggnkvLGHyI5/k8auZl4BuIgWFXmVanCUu9hD0wr35c= dummy-key"
}

variable "region" {
  description = "The AWS region to deploy in"
  default     = "eu-west-1"
}

