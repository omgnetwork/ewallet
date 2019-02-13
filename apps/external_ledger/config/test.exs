use Mix.Config

config :external_ledger, ExternalLedger.Repo,
  adapter: Ecto.Adapters.Postgres,
  pool: Ecto.Adapters.SQL.Sandbox,
  url: {:system, "EXTERNAL_LEDGER_DATABASE_URL", "postgres://localhost/external_ledger_test"},
  migration_timestamps: [type: :naive_datetime_usec],
  queue_target: 1_000,
  queue_interval: 5_000
