# The first apply runs with local state (backend_override.tf, see README),
# because the bucket does not exist yet; the state is then migrated here.
terraform {
  backend "s3" {
    key = "0-bootstrap/tf-prerequisites/terraform.tfstate"
  }
}
