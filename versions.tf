terraform {
  required_version = "~> 1"

  required_providers {
    aws = {
      version = "~> 3"
      source  = "hashicorp/aws"
    }
    local = {
      version = "~> 2"
      source  = "hashicorp/local"
    }
    random = {
      version = "~> 3"
      source  = "hashicorp/random"
    }
  }
}

