use Mix.Config

config :url_dispatcher,
  ecto_repos: [],
  port: System.get_env("EWALLET_PORT") || 3000
