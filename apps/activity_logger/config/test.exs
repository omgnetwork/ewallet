use Mix.Config

config :activity_logger, ActivityLogger.Repo,
  adapter: Ecto.Adapters.Postgres,
  pool: Ecto.Adapters.SQL.Sandbox,
  url: {:system, "DATABASE_URL", "postgres://localhost/ewallet_test"},
  migration_timestamps: [type: :naive_datetime_usec],
  queue_target: 5_000,
  queue_interval: 10_000
