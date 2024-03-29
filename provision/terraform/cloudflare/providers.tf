terraform {

  required_version = "~> 1.3.0"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "3.33.1"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.2.1"
    }
    sops = {
      source  = "carlpett/sops"
      version = "0.7.2"
    }
  }

  cloud {
    organization = "alekssro"
    workspaces {
      name = "home-lab-cloudflare"
    }
  }
}
