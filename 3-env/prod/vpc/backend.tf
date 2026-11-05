terraform {
  backend "s3" {
    key = "3-env/prod/vpc/terraform.tfstate"
  }
}
