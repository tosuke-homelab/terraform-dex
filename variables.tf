variable "PROJECT_ID" {
  type        = string
  description = "The project ID to deploy to"
}

variable "PROJECT_REGION" {
  type        = string
  description = "The region to deploy to"
}

variable "DEX_DB_URL" {
  type        = string
  description = "The URL of the database to connect to"
}

variable "DEX_GITHUB_CLIENT_ID" {
  type        = string
  description = "The GitHub OAuth client ID"
}

variable "DEX_GITHUB_CLIENT_SECRET_SECRET_ID" {
  type        = string
  description = "The GCP Secret ID of the GitHub OAuth client secret"
}
