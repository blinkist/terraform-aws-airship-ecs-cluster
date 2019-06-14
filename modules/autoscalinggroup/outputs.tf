output "asg_name" {
  description = "The name of the autoscaling group"
  value       = element(concat(aws_autoscaling_group.this.*.name, list("")), 0)
}
