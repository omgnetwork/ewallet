# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :kubera_api,
  namespace: KuberaAPI

# Configures the endpoint
config :kubera_api, KuberaAPI.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: KuberaAPI.V1.ErrorView, accepts: ~w(json)]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :kubera_api, :generators,
  context_app: false

# Maps accept header to a supported version implementation
# Run `mix deps.clean --build mime` when updaing this mapping.
config :mime, :types, %{
  "application/vnd.omisego.v1+json" => [:v1]
}

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
