variable "db" {
  type = object({
    type               = string
    name               = string
    host               = string
    user               = string
    password_secret_id = string
  })
}

variable "github_client_id" {
  type = string
}

variable "github_client_secret_secret_id" {
  type = string
}
