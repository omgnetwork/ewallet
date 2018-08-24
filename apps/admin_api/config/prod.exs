use Mix.Config

config :admin_panel, base_url: {:system, "BASE_URL"}

config :admin_api, AdminAPI.V1.Endpoint,
  debug_errors: true,
  check_origin: false
