# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :ewallet_api,
  namespace: EWalletAPI,
  ecto_repos: [],
  settings: [
    :base_url,
    :enable_standalone,
    :sender_email,
    :redirect_url_prefixes
  ]

# Configures the endpoint for websockets
config :ewallet_api, EWalletAPI.Endpoint,
  error_handler: EWalletAPI.V1.ErrorHandler,
  render_errors: [
    view: EWalletAPI.ErrorView,
    accepts: ~w(json),
    default_format: "json"
  ]

config :ewallet_api, EWalletAPI.V1.Endpoint,
  render_errors: [
    view: EWalletAPI.ErrorView,
    accepts: ~w(json),
    default_format: "json"
  ],
  pubsub: [
    name: EWalletAPI.PubSub,
    adapter: Phoenix.PubSub.PG2
  ]

config :ewallet_api, :generators, context_app: false

# Two configs need to be added to have a new EWallet API version:
#
# 1. `ewallet_api.api_versions`
#    This tells what router should handle the specified accept header.
# 2. `mime.types`
#    This tells Phoenix what extension type it should match the response to.

# Maps an accept header to the respective router version.
config :ewallet_api, :api_versions, %{
  "application/vnd.omisego.v1+json" => %{
    name: "v1",
    router: EWalletAPI.V1.Router,
    endpoint: EWalletAPI.V1.Endpoint,
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
  server_name: (:inet.gethostname() |> elem(1) |> to_string()),
  included_environments: [:prod]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
