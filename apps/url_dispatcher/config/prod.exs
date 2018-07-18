use Mix.Config

config :url_dispatcher,
  ecto_repos: [],
  serve_endpoints: true,
  port: {:system, "PORT", 4000}

config :admin_panel, start_with_no_watch: true
