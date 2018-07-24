use Mix.Config

config :admin_panel, base_url: {:system, "BASE_URL"}

# Configs for Bamboo emailing library
config :admin_api, AdminAPI.Mailer,
  adapter: Bamboo.SMTPAdapter,
  server: {:system, "SMTP_HOST"},
  port: {:system, "SMTP_PORT"},
  username: {:system, "SMTP_USER"},
  password: {:system, "SMTP_PASSWORD"}

config :admin_api, AdminAPI.V1.Endpoint,
  debug_errors: true,
  check_origin: false
