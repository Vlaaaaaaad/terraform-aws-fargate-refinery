data "local_file" "rules" {
  filename = var.refinery_rules_file_path
}

resource "aws_ssm_parameter" "rules" {
  name        = "/${var.name}/rules"
  description = "The Base64-encoded Refinery rules"

  type  = "SecureString"
  tier  = "Advanced"
  value = data.local_file.rules.content_base64

  tags = local.tags
}
