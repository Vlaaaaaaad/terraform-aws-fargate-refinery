data "aws_partition" "current" {
}

data "aws_region" "current" {
}

data "aws_caller_identity" "current" {
}

data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  azs             = var.azs != [] ? var.azs : data.aws_availability_zones.available.names
  vpc_id          = var.vpc_id == "" ? module.vpc[0].vpc_id : var.vpc_id
  certificate_arn = var.acm_certificate_arn == "" ? module.certificate.this_acm_certificate_arn : var.acm_certificate_arn

  refinery_url = "https://${coalesce(
    element(concat(aws_route53_record.refinery.*.fqdn, [""]), 0),
    module.alb.this_lb_dns_name,
    "_"
  )}"

  tags = merge(
    {
      "Name" = var.name
    },
    var.tags,
  )
}
