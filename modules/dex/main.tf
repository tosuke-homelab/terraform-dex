locals {
  name = "dexidp"

  github = {
    clientID     = var.github_client_id
    clientSecret = var.github_client_secret
  }

  db = regex("^(?P<scheme>[^:/?#]+)://(?P<user>[^:/?#]+):(?P<password>[^:/?#]+)@(?P<host>[^:/?#]+)(?::(?P<port>[^:/?#]+))?/(?P<database>[^:/?#]+)$", var.db_url)

  config = {
    issuer = "https://id.tosuke.me"
    storage = {
      type = local.db.scheme
      config = {
        host     = local.db.host
        port     = coalesce(tonumber(local.db.port), local.db.scheme == "mysql" ? 3306 : 5432)
        user     = local.db.user
        password = local.db.password
        database = local.db.database
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
          clientSecret = local.github.clientSecret
          redirectURI  = "https://id.tosuke.me/callback"
          orgs = [
            { name = "tosuke-homelab" },
            {
              name  = "linckage-community"
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
    "app-name" : local.name
  }

  serviceTemplate = {

  }
}

resource "google_service_account" "dex_sa" {
  account_id  = "${local.name}-sa"
  description = "Service Account for ${local.name}"
}

resource "google_secret_manager_secret" "dex_config" {
  secret_id = "${local.name}_dex_config"

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
  secret_id  = google_secret_manager_secret.dex_config.id
  role       = "roles/secretmanager.secretAccessor"
  member     = "serviceAccount:${google_service_account.dex_sa.email}"
  depends_on = [
    google_service_account.dex_sa,
    google_secret_manager_secret.dex_config
  ]
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

  name     = "${local.name}-${each.key}"
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
          version = "latest"
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

      volume_mounts {
        name       = "config"
        mount_path = "/etc/dex/cfg"
      }
    }
  }

  depends_on = [google_secret_manager_secret_version.dex_config_data]
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
