use Mix.Config

config :url_dispatcher,
  ecto_repos: [],
  port: System.get_env("PORT") || 3000
