use Mix.Config

config :admin_api, AdminAPI.Endpoint,
  http: [port: System.get_env("ADMIN_API_PORT")],
  url: [host: System.get_env("ADMIN_API_HOST"), port: System.get_env("ADMIN_API_PORT")]
