terraform {
  backend "s3" {
    bucket       = "s3-bucket-utrains" # Replace with a globally unique S3 bucket name
    key          = "environment/prod/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }

}