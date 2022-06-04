terraform {

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "3.15.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "2.1.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = "0.7.1"
    }
  }

  backend "s3" {
    bucket = var.tf_backend_bucket
    key    = var.tf_backend_key
  }
}


