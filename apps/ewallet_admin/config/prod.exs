use Mix.Config

config :ewallet_admin, EWalletAdmin.Endpoint,
  http: [port: System.get_env("ADMIN_API_PORT")],
  url: [host: System.get_env("ADMIN_API_HOST"), port: System.get_env("ADMIN_API_PORT")]
