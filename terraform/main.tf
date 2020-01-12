terraform {
  required_version = "~> 0.12"

  backend "s3" {
    encrypt = true
    bucket  = "aws-machine-learn-pfraczyk" #put your unique bucket name here which has to be created before
    key     = "development/terraform.tfstate"
  }
}