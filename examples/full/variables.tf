variable "public_key" {
  type        = string
  description = "The public key for the SSH key needed to SSH to the EC2 instances in the ECS cluster"
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAACEApggnkvLGHyI5/k8auZl4BuIgWFXmVanCUu9hD0wr35c= dummy-key"
}

variable "region" {
  type        = string
  description = "The AWS region to deploy in"
  default     = "eu-west-1"
}

variable "aws_route53_dns_zone_id" {
  type        = string
  description = "Route53 DNS zone ID"
  default     = ""
}
