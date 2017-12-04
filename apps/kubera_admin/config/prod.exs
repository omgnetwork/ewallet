use Mix.Config

config :kubera_admin, KuberaAdmin.Endpoint,
  http: [port: System.get_env("ADMIN_API_PORT")],
  url: [host: System.get_env("ADMIN_API_HOST"), port: System.get_env("ADMIN_API_PORT")]
