# IAM Access Analyzer for external access: finds resources (S3 buckets, IAM
# roles, KMS keys, ...) in any account that are shared outside the
# organization. The external access analyzer is free; the unused access
# analyzer (paid) is not created.

resource "aws_organizations_delegated_administrator" "access_analyzer" {
  account_id        = local.accounts_map[local.lz_config.org.access_analyzer.admin_account]
  service_principal = "access-analyzer.amazonaws.com"
}

resource "aws_accessanalyzer_analyzer" "org" {
  provider      = aws.security_tooling
  analyzer_name = local.lz_config.org.access_analyzer.analyzer_name
  type          = "ORGANIZATION"

  depends_on = [aws_organizations_delegated_administrator.access_analyzer]
}
