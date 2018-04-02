# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :admin_panel,
  namespace: AdminPanel,
  ecto_repos: [],
  dist_path: Path.expand("../priv/dist/", __DIR__),
  webpack_watch: false

# Configures the endpoint
config :admin_panel, AdminPanel.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: AdminPanel.ErrorView, accepts: ~w(html json)]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
