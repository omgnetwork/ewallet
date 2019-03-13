use Mix.Config

config :ewallet_db, EWalletDB.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  url: {:system, "DATABASE_URL", "postgres://localhost/ewallet_test"},
  queue_target: 10_000,
  queue_interval: 60_000
