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
      name = "terraform-dex"
    }
  }
}

provider "google" {
  project = var.PROJECT_ID
  region  = var.PROJECT_REGION
}

module "dex" {
  source = "./modules/dex"
  db = {
    type               = var.DEX_DB_TYPE
    name               = var.DEX_DB
    host               = var.DEX_DB_HOST
    user               = var.DEX_DB_USER
    password_secret_id = var.DEX_DB_PASSWORD_SECRET_ID
  }
  github_client_id               = var.DEX_GITHUB_CLIENT_ID
  github_client_secret_secret_id = var.DEX_GITHUB_CLIENT_SECRET_SECRET_ID
}
