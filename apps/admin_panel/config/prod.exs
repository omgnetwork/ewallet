use Mix.Config

# We need to serve admin assets using a precompiled static
# cache manifest in production.
config :admin_panel, AdminPanel.Endpoint, cache_static_manifest: "priv/static/cache_manifest.json"

# Webpack watching is always disabled in production.
config :admin_panel,
  webpack_watch: false
