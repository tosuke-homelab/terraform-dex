terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.63.1"
    }
  }

  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "tosuke-homelab"

    workspaces {
      name = "terraform-gcloud"
    }
  }
}

provider "google" {
  project = var.PROJECT_ID
  region  = var.PROJECT_REGION
}

module "dex" {
  source               = "./modules/dex"
  db_url               = var.DEX_DB_URL
  github_client_id     = var.DEX_GITHUB_CLIENT_ID
  github_client_secret = var.DEX_GITHUB_CLIENT_SECRET
}
