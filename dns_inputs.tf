variable "acm_certificate_arn" {
  description = "The ARN of a certificate issued by AWS ACM. If empty, a new ACM certificate will be created and validated using Route53 DNS"
  type        = string
  default     = ""
}

variable "acm_certificate_domain_name" {
  description = "The Route53 domain name to use for ACM certificate. Route53 zone for this domain should be created in advance. Specify if it is different from value in `route53_zone_name`"
  type        = string
  default     = ""
}

variable "create_route53_record" {
  description = "Whether to create Route53 record for Refinery"
  type        = bool
  default     = true
}

variable "route53_zone_name" {
  description = "The Route53 zone name to create ACM certificate in and main A-record, without trailing dot"
  type        = string
  default     = ""
}

variable "route53_record_name" {
  description = "The name of Route53 record to create ACM certificate in and main A-record. If `null` is specified, `var.name` is used instead. Provide empty string to point root domain name to ALB"
  type        = string
  default     = null
}
