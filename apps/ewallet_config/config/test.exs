use Mix.Config

config :ewallet_config, EWalletConfig.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  url: {:system, "DATABASE_URL", "postgres://localhost/ewallet_test"},
  queue_target: 1_000,
  queue_interval: 5_000
