job "fjarrkontrollen" {
  datacenters = ["gubdc1"]
  type = "service"

  vault {
    policies = ["nomad-server"]
    change_mode = "restart"
  }

  update {
    max_parallel = 1
    min_healthy_time = "10s"
    healthy_deadline = "5m"
    progress_deadline = "10m"
    auto_revert = false
    canary = 0
  }

  migrate {
    max_parallel = 1
    health_check = "checks"
    min_healthy_time = "10s"
    healthy_deadline = "5m"
  }

  group "postgres" {
    count = 1

    network {
      mode = "bridge"
    }

    volume "postgres-data" {
      type = "host"
      read_only = false
      source = "fjarrkontrollen-[[.deploy.stage]]-postgres-data"
    }

    volume "postgres-initdb" {
      type = "host"
      read_only = true
      source = "fjarrkontrollen-[[.deploy.stage]]-postgres-initdb"
    }

    service {
      name = "fjarrkontrollen-postgres-[[.deploy.stage]]"
      port = [[.ports.fjarrkontrollen_postgres_port]]

      connect {
        sidecar_service{}
      }
    }

    restart {
      attempts = 2
      interval = "30m"
      delay = "15s"
      mode = "fail"
    }

    task "postgres" {
      driver = "docker"

      volume_mount {
        volume = "postgres-data"
        destination = "/var/lib/postgresql/data"
        read_only = false
      }

      volume_mount {
        volume = "postgres-initdb"
        destination = "/docker-entrypoint-initdb.d"
        read_only = true
      }

      template {
        data = <<EOF
{{with secret "secret/apps/fjarrkontrollen/[[.deploy.stage]]"}}
POSTGRES_DB = "{{.Data.data.db_name}}"
POSTGRES_USER = "{{.Data.data.db_user}}"
POSTGRES_PASSWORD = "{{.Data.data.db_password}}"
{{end}}
PGPORT = "[[.ports.fjarrkontrollen_postgres_port]]"
EOF
        destination = "secrets/config.env"
        env = true
      }

      config {
        image = "docker.ub.gu.se/fjarrkontrollen-postgres:[[.deploy.git_revision]]"
        args = ["postgres", "-c", "config_file=/etc/postgresql/postgresql.conf"]

        auth {
          username = "[[.docker.auth.username]]"
          password = "[[.docker.auth.password]]"
        }
      }

      resources {
        cpu    = 500 # 500 MHz
        memory = 1024 # 1024MB
      }
    }
  }

  group "frontend" {
    count = 1

    network {
      mode = "bridge"
      port "frontend" {
        to = [[.ports.fjarrkontrollen_frontend_port]]
      }
    }

    service {
      name = "fjarrkontrollen-frontend-[[.deploy.stage]]"

      port = "frontend"

      tags = ["haproxy"]

      meta {
        hostname = "[[.deploy.frontend_hostname]]"
      }
    }

    task "frontend" {
      driver = "docker"

      # TODO: Could use env instead of template?
      template {
        data = <<EOF
EMBER_ENVIRONMENT = "[[.deploy.stage]]"
BACKEND_SERVICE_HOSTNAME = "[[.deploy.backend_hostname]]"
EOF
        destination = "secrets/config.env"
        env = true
      }

      config {
        image = "docker.ub.gu.se/fjarrkontrollen-frontend:[[.deploy.frontend_git_revision]]"

        auth {
          username = "[[.docker.auth.username]]"
          password = "[[.docker.auth.password]]"
        }
      }

      resources {
        cpu    = 500 # 500 MHz
        memory = 512 # 256MB
      }
    }
  }

  group "backend" {
    count = 1

    network {
      mode = "bridge"
      port "backend" {
        to = [[.ports.fjarrkontrollen_rails_port]]
      }
    }

    service {
      name = "fjarrkontrollen-backend-[[.deploy.stage]]"
      port = "backend" # Need to prefix with service name and stage, think this might be global?

      tags = ["haproxy"]

      meta {
        hostname = "[[.deploy.backend_hostname]]"
      }

      connect {
        sidecar_service {
          tags = ["sidecar-proxy"]
          proxy {
            upstreams {
              destination_name = "fjarrkontrollen-postgres-[[.deploy.stage]]"
              local_bind_port  = [[.ports.fjarrkontrollen_postgres_port]]
            }
          }
        }
      }
    }

    task "backend" {
      driver = "docker"

      template {
        data = <<EOF
RAILS_ENV =  "[[.deploy.stage]]"
RAILS_PORT = "[[.ports.fjarrkontrollen_rails_port]]"
{{with secret "secret/apps/fjarrkontrollen/[[.deploy.stage]]"}}
RAILS_SECRET_KEY_BASE = "{{.Data.data.secret_key_base}}"
RAILS_DB_HOST = "${NOMAD_UPSTREAM_IP_fjarrkontrollen-postgres-[[.deploy.stage]]}"
RAILS_DB_PORT = "${NOMAD_UPSTREAM_PORT_fjarrkontrollen-postgres-[[.deploy.stage]]}"
RAILS_DB = "{{.Data.data.db_name}}"
RAILS_DB_USER = "{{.Data.data.db_user}}"
RAILS_DB_PASSWORD = "{{.Data.data.db_password}}"
ILL_SECRET_ACCESS_TOKEN="{{.Data.data.backend_access_token}}"
ILL_EMAIL_SUBJECT_PREFIX="{{.Data.data.backend_email_subject_prefix}}"
ILL_KOHA_SVC_URL="{{.Data.data.koha_svc_url}}"
ILL_KOHA_USER="{{.Data.data.koha_user}}"
ILL_KOHA_PASSWORD="{{.Data.data.koha_password}}"
{{end}}
EOF
        destination = "secrets/config.env"
        env = true
      }

      config {
        image = "docker.ub.gu.se/fjarrkontrollen-backend:[[.deploy.backend_git_revision]]"
        args = ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]

        auth {
          username = "[[.docker.auth.username]]"
          password = "[[.docker.auth.password]]"
        }
      }

      resources {
        cpu    = 500 # 500 MHz
        memory = 512 # 512MB
      }
    }
  }
}
