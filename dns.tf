data "aws_route53_zone" "this" {
  count = var.create_route53_record ? 1 : 0

  name         = var.route53_zone_name
  private_zone = false
}

resource "aws_route53_record" "refinery" {
  count = var.create_route53_record ? 1 : 0

  zone_id = data.aws_route53_zone.this[0].zone_id
  name    = var.route53_record_name != null ? var.route53_record_name : var.name
  type    = "A"

  alias {
    name                   = module.alb.lb_dns_name
    zone_id                = module.alb.lb_zone_id
    evaluate_target_health = true
  }
}

module "certificate" {
  source  = "terraform-aws-modules/acm/aws"
  version = "v2.12.0"

  create_certificate = var.acm_certificate_arn == "" ? true : false

  domain_name = var.acm_certificate_domain_name == "" ? join(".", [var.name, var.route53_zone_name]) : var.acm_certificate_domain_name
  zone_id     = var.acm_certificate_arn == "" ? element(concat(data.aws_route53_zone.this.*.id, [""]), 0) : ""

  tags = local.tags
}
