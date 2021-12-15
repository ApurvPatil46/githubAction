# Github actions to create and access AWS S3 bucket with terraform

## Approach
1. Setup AWS account 
2. Configure AWS provider
3. Configure terraform remote state
4. Create remote state bucket
5. S3 bucket with Terraform
6. Create your pipeline
7. Configure credentials with github

#### 1. Setup AWS account - 
The first step when working with a tool like Terraform is to setup the thing that will contain our resources.You can find your credentials by navigating to the AWS IAM service from within AWS and navigating to the “security credentials” tab. From here you can download your access key and secret key. You’ll need these credentials to give to Github Actions later so stick them somewhere safe for now.

##### NOTE- 
The account associated with your access key will need to have access to the (yet to be created) S3 bucket. One of the simplest ways to do this is by granting your user the user the AmazonS3FullAccess IAM Permission. But you should note that granting this permission will give your user full access to S3 — which is an unnecessarily broad permission. You could later tighten this policy up by only granting access to read/write/delete on your new S3 bucket.

#### 2. Configure AWS provider-
Now you should have an AWS account and access keys ready to go. What we want to do now is setup Terraform to reference our AWS account.Go ahead and create a file (you can give it any name) in our case we’ve called it demo.tf and add in the following code. This code block will tell Terraform that we want to provision AWS resources and that we’re defaulting the resource creation to the eu-central-1 region within AWS (feel free to change the region if it’s important to you).

```
provider "aws" {
  version = "~> 2.0"
  region  = "eu-central-1"
}
```
#### 3. Configure terraform remote state-
Now we’ve got our provider setup we’ll also want to configure our remote state. So go ahead and add the following config to your previously created file

##### Note: 
we’ll discuss what replace the YOUR_REMOTE_STATE_BUCKET_NAME and YOUR_REMOTE_STATE_KEY tokens in just a moment.

```
terraform {
  backend "s3" {
    bucket = "[YOUR_REMOTE_STATE_BUCKET_NAME]"
    key    = "[YOUR_REMOTE_STATE_KEY]"
    region = "eu-central-1"
  }
}
```
* UNDERSTANDING TERRAFORM REMOTE STATE
State is what Terraform uses to compare the current state (note the wording here) of your infrastructure against the desired state. You can either create this state locally (i.e Terraform writes to a file) or you can do it remotely.We need to create our state remotely if we are to run it on Github Actions. Without remote state, Terraform generates a local file, but it wouldn’t commit it to GitHub, so we’d lose the state data and end up in a sticky situation. With remote state we avoid this problem by keeping state out of our pipeline in separate persistent storage.

* CREATE A REMOTE STATE BUCKET
in order to use remote state we need a bucket. So go ahead and create a bucket in your AWS account for your remote state. You might want to call it something like “my-remote-bucket”. You can accept pretty much all the defaults for your bucket, but do ensure that it’s private as you don’t want to share it with the world.

#### 4. Create remote state bucket-
We’ve got our Terraform setup and configured, all that’s left to do is to script our resource so that Terraform knows what we want to create. Since we’re creating an S3 resource, so let’s go ahead and do that. Add the following code resource block to your .tf file. Be sure to substitute [YOUR_BUCKET_NAME] with the actual bucket name that you want to use for your resource.

```
resource "aws_s3_bucket" "s3Bucket" {
  bucket = "[YOUR_BUCKET_NAME]"
  acl    = "public-read"

  policy = <<EOF
{
  "Id": "MakePublic",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::[YOUR_BUCKET_NAME]/*",
      "Principal": "*"
    }
  ]
}
EOF
```
#### 5. S3 bucket with terraform - 
Provides a S3 bucket resource.
```
resource "aws_s3_bucket" "s3Bucket" {
  bucket = "[YOUR_BUCKET_NAME]"
  acl    = "public-read"
  }
```
#### 6. Create your pipeline - 
You could in fact run it locally at this point, but we ideally want to have your configuration running on a build tool (in this case: Github Actions).
```
name: Deploy Infrastructure

on:
  push:
    branches:
      - master

jobs:
  tf_fmt:
    name: Deploy Site
    runs-on: ubuntu-latest
    steps:

    - name: Checkout Repo
      uses: actions/checkout@v1

    - name: Terraform Init
      uses: hashicorp/terraform-github-actions/init@v0.4.0
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        TF_ACTION_WORKING_DIR: 'terraform'
        AWS_ACCESS_KEY_ID:  ${{ secrets.AWS_ACCESS_KEY_ID }}
        AWS_SECRET_ACCESS_KEY:  ${{ secrets.AWS_SECRET_ACCESS_KEY }}

    - name: Terraform Validate
      uses: hashicorp/terraform-github-actions/validate@v0.3.7

    - name: Terraform Apply
      uses: hashicorp/terraform-github-actions/apply@v0.4.0
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        TF_ACTION_WORKING_DIR: 'terraform'
        AWS_ACCESS_KEY_ID:  ${{ secrets.AWS_ACCESS_KEY_ID }}
        AWS_SECRET_ACCESS_KEY:  ${{ secrets.AWS_SECRET_ACCESS_KEY }}

    - name: Sync S3
      uses: jakejarvis/s3-sync-action@master
      env:
        SOURCE_DIR: './src'
        AWS_REGION: 'eu-central-1'
        AWS_S3_BUCKET: '[YOUR_BUCKET_NAME_HERE]'
        AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
        AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

#### 7. Configure credentials with github
Before the pipeline will run though we need to go back to our AWS access credentials and add those to our repo. Navigate to github and then to your repository, select the option for settings and then secrets. On the security credentials screen you can add your AWS_SECRET_ACCESS_KEY and your AWS_ACCESS_KEY_ID to your repo.In order to get our pipeline working, all you need to do is copy the following file and add it to your .github/workflows directory. And as before, don’t forget to substitute the [YOUR_BUCKET_NAME_HERE] token with your bucket name.
