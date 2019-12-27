data "aws_iam_policy_document" "ecs_service" {
  count = var.create ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_service" {
  count              = var.create ? 1 : 0
  name               = "${var.name}-ecs-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_service[0].json
}

resource "aws_iam_role_policy_attachment" "ecs_service_role_attach" {
  count      = var.create ? 1 : 0
  role       = aws_iam_role.ecs_service[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}

resource "aws_iam_instance_profile" "ecs_cluster_ec2_instance_profile" {
  count = var.create ? 1 : 0
  name  = "${var.name}-ecs-cluster-instance-profile"
  role  = aws_iam_role.ecs_cluster_ec2_instance_role[0].id

  lifecycle {
    create_before_destroy = true
  }

  # Messed up hack, but works, after profile creation, it take a little before it can be used by EC2
  provisioner "local-exec" {
    command = "sleep 30"
  }
}

data "aws_iam_policy_document" "ec2_instance" {
  count = var.create ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_cluster_ec2_instance_role" {
  count              = var.create ? 1 : 0
  name               = "${var.name}_ecs-cluster-ec2_instance_role"
  description        = var.iam_role_description
  assume_role_policy = data.aws_iam_policy_document.ec2_instance[0].json

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy" "ecs_cluster_ec2_instance_permissions" {
  count = var.create ? 1 : 0
  name  = "${var.name}-ecs-instance-permissions"
  role  = aws_iam_role.ecs_cluster_ec2_instance_role[0].id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecs:CreateCluster",
        "ecs:DeregisterContainerInstance",
        "ecs:DiscoverPollEndpoint",
        "ecs:Poll",
        "ecs:StartTask",
        "ecs:RegisterContainerInstance",
        "ecs:StartTelemetrySession",
        "ecs:Submit*",
        "ecr:BatchCheckLayerAvailability",
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer",
        "ecr:GetAuthorizationToken",
        "cloudwatch:DescribeAlarms",
        "cloudwatch:PutMetricAlarm",
        "cloudwatch:PutMetricData",
        "cloudwatch:GetMetricStatistics",
        "cloudwatch:ListMetrics",
        "ec2:Describe*",
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    }
  ]
}
EOF

}

