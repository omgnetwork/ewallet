use Mix.Config

# Configs for Bamboo emailing library
config :admin_api, AdminAPI.Mailer,
  adapter: Bamboo.SMTPAdapter,
  server: System.get_env("SMTP_HOST"),
  port: System.get_env("SMTP_PORT"),
  username: System.get_env("SMTP_USER"),
  password: System.get_env("SMTP_PASSWORD")
