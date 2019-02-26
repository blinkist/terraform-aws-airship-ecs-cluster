terraform {
  required_version = "< 0.12"
}

provider "aws" {
  region                      = "${var.region}"
  skip_requesting_account_id  = true            # this can be tricky
  skip_get_ec2_platforms      = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
  skip_credentials_validation = true
  version                     = "> 1.57"
}

variable "region" {
  default = "ap-southeast-2"
}
