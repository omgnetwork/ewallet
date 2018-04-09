use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :admin_api, AdminAPI.Endpoint,
  secret_key_base: "G1DLBdjjJSoSiQRa5Gf8YrWUx5yrX+JFmZx+UBk829W1+e0oJ9TYrW/GkIgrAdfm",
  server: false

config :admin_api,
  enable_client_auth: "true"

# Configs for Bamboo emailing library
config :admin_api, AdminAPI.Mailer,
  adapter: Bamboo.TestAdapter
