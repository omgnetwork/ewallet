use Mix.Config

config :admin_panel,
  dist_path: {:apply, {AdminPanel.Application, :dist_path, []}},
  webpack_watch: false

config :admin_panel, AdminPanel.Endpoint, cache_static_manifest: "priv/static/cache_manifest.json"
