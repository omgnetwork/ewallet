use Mix.Config

config :activity_logger, ActivityLogger.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  url: {:system, "DATABASE_URL", "postgres://localhost/ewallet_test"},
  queue_target: 1_000,
  queue_interval: 5_000
