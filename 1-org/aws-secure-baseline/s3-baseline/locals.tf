locals {
  lz_config    = yamldecode(file("${path.module}/../../../lzconfig.yaml"))
  region       = local.lz_config.global.home_region
  switch_role  = local.lz_config.global.switch_role_to_assume
  accounts_map = data.terraform_remote_state.org.outputs.accounts_id_map
  mgmt_account = data.terraform_remote_state.org.outputs.management_account_id
}
