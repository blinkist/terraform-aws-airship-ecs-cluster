output "ecs_instance_profile" {
  description = "ecs_instance_profile exports the instance profile of the EC2 instance"
  value = element(
    concat(
      aws_iam_instance_profile.ecs_cluster_ec2_instance_profile.*.arn,
      [""],
    ),
    0,
  )
}

output "ecs_instance_role" {
  description = "ecs_instance_role exports the IAM role of the EC2 instance"
  value = element(
    concat(aws_iam_role.ecs_cluster_ec2_instance_role.*.id, [""]),
    0,
  )
}

