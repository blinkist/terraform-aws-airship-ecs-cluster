output "cluster_id" {
  description = "ecs_cluster_id is the export of the ECS cluster id"
  value       = element(concat(aws_ecs_cluster.this.*.id, [""]), 0)
}

output "ecs_cluster_name" {
  description = "ecs_cluster_name exports the name of the ECS cluster"
  value       = var.name
}

output "ecs_instance_profile" {
  description = "aws_iam_role_autodiscovery_role exports the instance profile of the EC2 instance"
  value       = module.iam.ecs_instance_profile
}

output "ecs_instance_role" {
  description = "ecs_instance_role exports the IAM role of the EC2 instance"
  value       = module.iam.ecs_instance_role
}

output "asg_name" {
  description = "asg_name exports the name of the autoscalinggroup if one is created"
  value       = module.autoscalinggroup.asg_name
}

