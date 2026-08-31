pid_file = "/tmp/vault-agent.pid"

vault {
  address = "http://192.168.1.120:8200"
  retry {
    num_retries = 12
  }
}

auto_auth {
  method "approle" {
    mount_path = "auth/approle"
    config = {
      role_id_file_path                   = "/vault/auth/role-id"
      secret_id_file_path                 = "/vault/auth/secret-id"
      remove_secret_id_file_after_reading = false
    }
  }

  sink "file" {
    config = {
      path = "/run/hermes/vault-token"
      mode = 0600
    }
  }
}

template_config {
  static_secret_render_interval = "5m"
}

template {
  source      = "/vault/config/hermes.env.ctmpl"
  destination = "/run/hermes/hermes.env"
  perms       = 0640
}
