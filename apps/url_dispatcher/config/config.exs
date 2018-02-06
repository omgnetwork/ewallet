use Mix.Config

config :url_dispatcher,
  port: System.get_env("EWALLET_PORT") || 3000
