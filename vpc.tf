#tfsec:ignore:AWS082
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "v3.2.0"

  count = var.vpc_id == "" ? 1 : 0

  name = var.name

  azs            = local.azs
  cidr           = var.vpc_cidr
  public_subnets = var.vpc_public_subnets

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = local.tags
}
