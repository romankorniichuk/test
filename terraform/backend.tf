terraform {
  backend "s3" {
    bucket = "mytfbucketstate"
    key    = "terraform.tfstate"
    region = "eu-central-1"
  }
}