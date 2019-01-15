use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :admin_panel, AdminPanel.Endpoint, server: false

# We don't need to watch webpack assets during test.
config :admin_panel,
  webpack_watch: false
