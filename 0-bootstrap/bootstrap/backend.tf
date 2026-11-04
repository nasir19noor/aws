terraform {
  backend "s3" {
    key = "0-bootstrap/bootstrap/terraform.tfstate"
  }
}
