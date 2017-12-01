# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :kubera_admin,
  namespace: KuberaAdmin

# Configs for the endpoint
config :kubera_admin,
  KuberaAdmin.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    view: KuberaAdmin.ErrorView,
    accepts: ~w(json),
    default_format: "json"
  ]

# Config for Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Config for Phoenix's generators
config :kubera_admin, :generators,
  context_app: false

# Two configs need to be added to have a new Kubera Admin version:
#
# 1. `kubera_admin.api_versions`
#    This tells what router should handle the specified accept header.
# 2. `mime.types`
#    This tells Phoenix what extension type it should match the response to.

# Maps an accept header to the respective router version.
config :kubera_admin, :api_versions, %{
  "application/vnd.omisego.v1+json" => KuberaAdmin.V1.Router
}

# Maps accept header to an extension type so Phoenix knows
# what format to respond with.
# Run `mix deps.clean --build mime` when updaing this mapping.
config :mime, :types, %{
  "application/vnd.omisego.v1+json" => ["json"]
}

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
