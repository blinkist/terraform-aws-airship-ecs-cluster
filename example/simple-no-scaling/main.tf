data "aws_vpc" "selected" {
  default = true
}

data "aws_availability_zones" "available" {}

data "aws_subnet" "selected" {
  availability_zone = "${data.aws_availability_zones.available.names[0]}"
  default_for_az    = true
  vpc_id            = "${data.aws_vpc.selected.id}"
}

data "aws_security_group" "selected" {
  name   = "default"
  vpc_id = "${data.aws_vpc.selected.id}"
}

module "ecs_web" {
  source = "../.."

  name = "${terraform.workspace}-web"

  vpc_id     = "${data.aws_vpc.selected.id}"
  subnet_ids = ["${data.aws_subnet.selected.id}"]

  vpc_security_group_ids = ["${data.aws_security_group.selected.id}"]

  tags = {
    Environment = "${terraform.workspace}"
  }
}
