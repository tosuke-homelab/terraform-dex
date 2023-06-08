variable "db_url" {
  type = string
}

variable "github_client_id" {
  type = string
}

variable "github_client_secret" {
  type = string
  sensitive = true
}
