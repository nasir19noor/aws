# The role GitHub Actions assumes through OIDC (in place of Ollion's LZ CICD
# account and CodePipeline). No access key exists.

locals {
  cicd      = local.lz_config.bootstrap.cicd
  owner     = split("/", local.cicd.git_repo)[0]
  repo_name = split("/", local.cicd.git_repo)[1]
  ref       = "ref:refs/heads/${local.cicd.git_branch}"

  # The token's "sub" claim: repo:<owner>/<repo>:..., or with immutable IDs
  # repo:<owner>@<owner_id>/<repo>@<repo_id>:... when the owner turns that on.
  subjects = [
    "repo:${local.cicd.git_repo}:${local.ref}",
    "repo:${local.owner}@${local.cicd.git_owner_id}/${local.repo_name}@${local.cicd.git_repo_id}:${local.ref}",
  ]

  oidc_provider_arn = local.cicd.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : data.aws_iam_openid_connect_provider.github[0].arn
}

# One per account: set bootstrap.cicd.create_oidc_provider to false if it
# already exists.
resource "aws_iam_openid_connect_provider" "github" {
  count          = local.cicd.create_oidc_provider ? 1 : 0
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

data "aws_iam_openid_connect_provider" "github" {
  count = local.cicd.create_oidc_provider ? 0 : 1
  url   = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_role" "github" {
  name                 = local.cicd.role_name
  description          = "Assumed by ${local.cicd.git_repo} (${local.cicd.git_branch}) to deploy the landing zone."
  max_session_duration = 3600
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = local.oidc_provider_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          "token.actions.githubusercontent.com:sub" = local.subjects
        }
      }
    }]
  })
}

# The landing zone manages the organization, accounts, SCPs, Identity Center,
# CloudTrail and IAM, and assumes OrganizationAccountAccessRole in the member
# accounts, so the role is an administrator. Only main of this repository can
# assume it.
resource "aws_iam_role_policy_attachment" "github_admin" {
  role       = aws_iam_role.github.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
