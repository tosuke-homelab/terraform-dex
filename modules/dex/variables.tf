variable "db" {
  type = object({
    type               = string
    name               = string
    host               = string
    user               = string
    password_secret_id = string
  })
}

variable "github_connector" {
  type = object({
    client_id               = string
    client_secret_secret_id = string
  })
}
