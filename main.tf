locals {
  config = jsondecode(file("${path.module}/parameter.json")).data
}

module "dynamodb" {
  source = "./dynamodb-module"
  data   = local.config
}
