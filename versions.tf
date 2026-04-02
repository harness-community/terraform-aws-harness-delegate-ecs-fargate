terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
    harness = {
      source  = "harness/harness"
      version = "~> 0.0"
    }
  }
}
