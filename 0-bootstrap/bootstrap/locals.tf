locals {
  lz_config = yamldecode(file("${path.module}/../../lzconfig.yaml"))
}
