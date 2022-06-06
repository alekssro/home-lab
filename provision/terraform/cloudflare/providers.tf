terraform {

  required_version = "~> 1.2.0"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "3.16.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "2.2.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = "0.7.1"
    }
  }

  cloud {
    organization = "alekssro"

    workspaces {
      name = "home-lab-cloudflare"
    }
  }
}
