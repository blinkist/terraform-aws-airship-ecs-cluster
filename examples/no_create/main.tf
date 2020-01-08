/**
 * # Optional creation
 * 
 * Demonstrates that setting create to false doesn't generate any resources.
 */

terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  region                      = "eu-west-1"
  skip_get_ec2_platforms      = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
  skip_credentials_validation = true
  version                     = "~> 2.20"
}

provider "null" {
  version = "~> 2.1"
}

provider "template" {
  version = "~> 2.1"
}

module "ecs_web" {
  source = "../.."
  create = false
  name   = "${terraform.workspace}-nocreate"
}

