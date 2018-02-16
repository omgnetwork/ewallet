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
  sender_email: System.get_env("SENDER_EMAIL") || "admin@localhost"

# Configs for the endpoint
config :admin_api,
  AdminAPI.Endpoint,
  secret_key_base: System.get_env("SECRET_KEY_BASE"),
  render_errors: [
    view: AdminAPI.ErrorView,
    accepts: ~w(json),
    default_format: "json"
  ]

# Config for Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Config for Phoenix's generators
config :admin_api, :generators,
  context_app: false

# Configs for Bamboo emailing library
config :admin_api, AdminAPI.Mailer,
  adapter: Bamboo.LocalAdapter

# Config for CORSPlug
#
# CORS_ORIGINS may contain multiple comma-separated origins, therefore it needs
# to be splitted and trimmed. But since `config.exs` evaluates the options
# at compile time, it does not allow an assignment with anonymous functions,
# waiting to be executed at runtime.
#
# Because of this the anonymous function is invoked right away through
# `(fn -> ... end).()` in order for :origin to be assigned at compile time.
config :cors_plug,
  max_age: System.get_env("CORS_MAX_AGE") || 600, # Lowest common value of all browsers
  headers: ["Authorization", "Content-Type", "Accept", "Origin",
            "User-Agent", "DNT", "Cache-Control", "X-Mx-ReqToken",
            "Keep-Alive", "X-Requested-With", "If-Modified-Since",
            "X-CSRF-Token", "OMGAdmin-Account-ID"],
  methods: ["POST"],
  origin: (fn ->
    case System.get_env("CORS_ORIGINS") do
      nil -> [] # Disallow all origins if CORS_ORIGINS is not set
      origins -> origins |> String.trim() |> String.split(~r{\s*,\s*})
    end
  end).()

# Two configs need to be added to have a new EWallet Admin version:
#
# 1. `admin_api.api_versions`
#    This tells what router should handle the specified accept header.
# 2. `mime.types`
#    This tells Phoenix what extension type it should match the response to.

# Maps an accept header to the respective router version.
config :admin_api, :api_versions, %{
  "application/vnd.omisego.v1+json" => AdminAPI.V1.Router
}

# Maps accept header to an extension type so Phoenix knows
# what format to respond with.
# Run `mix deps.clean --build mime` when updaing this mapping.
config :mime, :types, %{
  "application/vnd.omisego.v1+json" => ["json"]
}

# Configs for Sentry exception reporting
config :sentry,
  dsn: System.get_env("SENTRY_DSN"),
  environment_name: Mix.env,
  enable_source_code_context: true,
  root_source_code_path: File.cwd!,
  tags: %{
    env: Mix.env,
    application: Mix.Project.config[:app]
  },
  server_name: elem(:inet.gethostname, 1),
  included_environments: [:prod]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
