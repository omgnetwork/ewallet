use Mix.Config

config :url_dispatcher,
  namespace: URLDispatcher,
  ecto_repos: [],
  serve_endpoints: {:system, "SERVE_ENDPOINTS", false},
  port: {:system, "PORT", 4000, {String, :to_integer}}

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
