terraform {
  backend "s3" {
    key = "1-org/aws-secure-baseline/iam-ebs-secure-baselines/terraform.tfstate"
  }
}
