terraform {
  backend "s3" {
    key = "3-env/nonprod/vpc/terraform.tfstate"
  }
}
