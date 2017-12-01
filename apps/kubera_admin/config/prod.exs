use Mix.Config

config :kubera_admin, KuberaAdmin.Endpoint,
  http: [port: System.get_env("PORT")],
  url: [host: System.get_env("HOST"), port: System.get_env("PORT")]
