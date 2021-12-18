provider "aws" {
  version = "~> 2.0"
  region  = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "terraform-remote-state-aws-ci"
    key    = "website"
    region = "us-east-1"
  }
}

resource "aws_s3_bucket" "s3Bucket" {
  bucket = "host-website-with-github-ci"
  acl    = "private"
  }
}
