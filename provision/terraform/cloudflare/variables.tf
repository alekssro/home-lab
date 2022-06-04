variable "tf_backend_bucket" {
  description = "S3 bucket for Terraform state"
  type        = string
  default     = "alekssro-terraform-states"
}

variable "tf_backend_key" {
  description = "S3 key for Terraform state"
  type        = string
  default     = "cloudflare/cloudflare.tfstate"
}

variable "sops_file" {
  description = "Sops file containing Cloudflare secrets"
  type        = string
  default     = "secret.sops.yaml"
}
