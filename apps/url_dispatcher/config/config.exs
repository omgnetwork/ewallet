use Mix.Config

config :url_dispatcher,
  ecto_repos: [],
  port: {:system, "PORT", 4000}

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
