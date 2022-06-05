terraform {

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "3.16.0"
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
    bucket         = "alekssro-terraform-states"
    key            = "cloudflare.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "terraform-state-lock"
  }
}
