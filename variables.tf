variable "PROJECT_ID" {
  type        = string
  description = "The project ID to deploy to"
}

variable "PROJECT_REGION" {
  type        = string
  description = "The region to deploy to"
}

variable "DEX_DB_HOST" {
  type        = string
  description = "The database host"
}

variable "DEX_DB_TYPE" {
  type        = string
  description = "The database type"
}

variable "DEX_DB" {
  type = string
  description = "The database name"
}

variable "DEX_DB_USER" {
  type        = string
  description = "The database user"
}

variable "DEX_DB_PASSWORD" {
  type        = string
  description = "The database password"
}

variable "DEX_DB_PASSWORD_SECRET_ID" {
  type        = string
  description = "The GCP Secret ID of the database password"
}
  
variable "DEX_GITHUB_CLIENT_ID" {
  type        = string
  description = "The GitHub OAuth client ID"
}

variable "DEX_GITHUB_CLIENT_SECRET_SECRET_ID" {
  type        = string
  description = "The GCP Secret ID of the GitHub OAuth client secret"
}
