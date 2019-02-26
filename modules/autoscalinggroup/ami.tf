/* "Amazon ECS Ami is the AMI of choice" */
data "aws_ami" "ecs_ami" {
  count       = "${var.ami == "" ? "1" : "0"}"
  most_recent = true

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }
}
