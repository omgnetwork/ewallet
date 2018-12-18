# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :admin_api,
  namespace: AdminAPI,
  ecto_repos: [],
  settings: [
    :sender_email
  ]

# Configs for the endpoint
config :admin_api, AdminAPI.Endpoint,
  secret_key_base: {:system, "SECRET_KEY_BASE"},
  error_handler: AdminAPI.V1.ErrorHandler,
  render_errors: [
    view: AdminAPI.ErrorView,
    accepts: ~w(json),
    default_format: "json"
  ]

config :admin_api, AdminAPI.V1.Endpoint,
  render_errors: [
    view: AdminAPI.ErrorView,
    accepts: ~w(json),
    default_format: "json"
  ],
  pubsub: [
    name: AdminAPI.PubSub,
    adapter: Phoenix.PubSub.PG2
  ]

# Config for Phoenix's generators
config :admin_api, :generators, context_app: false

# Two configs need to be added to have a new EWallet Admin version:
#
# 1. `admin_api.api_versions`
#    This tells what router should handle the specified accept header.
# 2. `mime.types`
#    This tells Phoenix what extension type it should match the response to.

# Maps an accept header to the respective router version.
config :admin_api, :api_versions, %{
  "application/vnd.omisego.v1+json" => %{
    name: "v1",
    router: AdminAPI.V1.Router,
    endpoint: AdminAPI.V1.Endpoint,
    websocket_serializer: EWallet.Web.V1.WebsocketResponseSerializer
  }
}

# Maps accept header to an extension type so Phoenix knows
# what format to respond with.
# Run `mix deps.clean --build mime` when updaing this mapping.
config :mime, :types, %{
  "application/vnd.omisego.v1+json" => ["json"]
}

# Configs for Sentry exception reporting
config :sentry,
  dsn: {:system, "SENTRY_DSN"},
  environment_name: Mix.env(),
  enable_source_code_context: true,
  root_source_code_path: File.cwd!(),
  tags: %{
    env: Mix.env(),
    application: Mix.Project.config()[:app]
  },
  server_name: elem(:inet.gethostname(), 1),
  included_environments: [:prod]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
