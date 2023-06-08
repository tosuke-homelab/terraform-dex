locals {
  github = {
    clientID                = var.github_connector.client_id
    clientSecretGCPSecretID = var.github_connector.client_secret_secret_id
  }

  config = {
    issuer = "https://id.tosuke.me"
    storage = {
      type = var.db.type
      config = {
        host     = var.db.host
        user     = var.db.user
        password = "{{ .Env.DB_PASSWORD }}"
        database = var.db.name
      }
    }
    web = { http = "0.0.0.0:8080" }
    grpc = {
      addr       = "0.0.0.0:8081"
      reflection = true
    }

    connectors = [
      {
        type = "github"
        id   = "github"
        name = "GitHub"
        config = {
          clientID     = local.github.clientID
          clientSecret = "{{ .Env.GITHUB_CLIENT_SECRET }}"
          redirectURI  = "https://id.tosuke.me/callback"
          orgs = [
            { name = "tosuke-homelab" },
            {
              name  = "linkage-community"
              teams = ["developers"]
            }
          ]
        }
      }
    ]
  }

  configData = yamlencode(local.config)

  location = "asia-northeast1"

  commonLabels = {
    "app-name" : "dexidp"
  }

  serviceTemplate = {

  }
}

resource "google_service_account" "dex_sa" {
  account_id  = "dexidp-sa"
  description = "Service Account for dexidp"
}

resource "google_secret_manager_secret" "dex_config" {
  secret_id = "dexidp-config"

  labels = local.commonLabels

  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_version" "dex_config_data" {
  secret = google_secret_manager_secret.dex_config.id

  secret_data = local.configData

  depends_on = [google_secret_manager_secret.dex_config]
}

resource "google_secret_manager_secret_iam_member" "dex_config_access" {
  secret_id = google_secret_manager_secret.dex_config.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.dex_sa.email}"
}

data "google_secret_manager_secret" "dex_db_password" {
  secret_id = var.db.password_secret_id
}

resource "google_secret_manager_secret_iam_member" "dex_db_password_access" {
  secret_id = data.google_secret_manager_secret.dex_db_password.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.dex_sa.email}"
}

data "google_secret_manager_secret" "dex_github_client_secret" {
  secret_id = local.github.clientSecretGCPSecretID
}

resource "google_secret_manager_secret_iam_member" "dex_github_client_secret_access" {
  secret_id = data.google_secret_manager_secret.dex_github_client_secret.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.dex_sa.email}"
}

locals {
  services = {
    web = {
      ports = {
        name           = "http1"
        container_port = 8080
      }
    }
    grpc = {
      ports = {
        name           = "h2c"
        container_port = 8081
      }
    }
  }
}

resource "google_cloud_run_v2_service" "services" {
  for_each = local.services

  name     = "dexidp-${each.key}"
  ingress  = "INGRESS_TRAFFIC_ALL"
  location = local.location

  template {
    labels          = local.commonLabels
    service_account = google_service_account.dex_sa.email

    scaling {
      min_instance_count = 0
      max_instance_count = 2
    }

    volumes {
      name = "config"
      secret {
        secret       = google_secret_manager_secret.dex_config.name
        default_mode = 292 # 0444
        items {
          version = google_secret_manager_secret_version.dex_config_data.version
          path    = "config.yaml"
          mode    = 292 # 0444
        }
      }
    }

    containers {
      name = "dex"

      image   = "docker.io/dexidp/dex:v2.35.3-distroless"
      command = ["/usr/local/bin/docker-entrypoint", "dex", "serve", "/etc/dex/cfg/config.yaml"]

      ports {
        name           = each.value.ports.name
        container_port = each.value.ports.container_port
      }

      env {
        name = "GITHUB_CLIENT_SECRET"
        value_source {
          secret_key_ref {
            secret  = data.google_secret_manager_secret.dex_github_client_secret.name
            version = "latest"
          }
        }
      }

      env {
        name = "DB_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = data.google_secret_manager_secret.dex_db_password.name
            version = "latest"
          }
        }
      }

      volume_mounts {
        name       = "config"
        mount_path = "/etc/dex/cfg"
      }
    }
  }
}

resource "google_cloud_run_v2_service_iam_binding" "dex_web_public" {
  name     = google_cloud_run_v2_service.services["web"].name
  location = local.location
  role     = "roles/run.invoker"
  members  = ["allUsers"]
}

resource "google_cloud_run_domain_mapping" "dex_web_domain" {
  location = local.location
  name     = "id.tosuke.me"

  metadata {
    namespace = google_cloud_run_v2_service.services["web"].project
    labels    = local.commonLabels
  }

  spec {
    route_name = google_cloud_run_v2_service.services["web"].name
  }
}
