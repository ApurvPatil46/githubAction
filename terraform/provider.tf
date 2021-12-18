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
  bucket = "Host-Website-With-Github-Ci"
  acl    = "public-read"

  policy = <<EOF
{
  "Id": "BucketPolicy",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllAccess",
      "Action": "s3:*",
      "Effect": "Allow",
      "Resource": [
         "arn:aws:s3:::Host-Website-With-Github-Ci",
         "arn:aws:s3:::Host-Website-With-Github-Ci/*"
      ],
      "Principal": "*"
    }
  ]
}
EOF

  website {
    index_document = "pricing.html"
  }
}
