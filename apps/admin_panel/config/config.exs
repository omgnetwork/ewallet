use Mix.Config

# General application configuration
config :admin_panel,
  namespace: AdminPanel,
  ecto_repos: [],
  dist_path: {:apply, {Utils.Helpers.PathResolver, :static_dir, [:admin_panel]}},
  webpack_watch: {:system, "WEBPACK_WATCH", false}

# Configures the endpoint
config :admin_panel, AdminPanel.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: AdminPanel.ErrorView, accepts: ~w(html json)]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
