terraform {
  required_version = ">= 0.13, < 0.15"

  required_providers {
    aws    = "~> 3"
    local  = "~> 2"
    random = "~> 3"
  }
}
