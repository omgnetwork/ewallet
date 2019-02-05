use Mix.Config

config :local_ledger_db, LocalLedgerDB.Repo,
  adapter: Ecto.Adapters.Postgres,
  pool: Ecto.Adapters.SQL.Sandbox,
  url: {:system, "LOCAL_LEDGER_DATABASE_URL", "postgres://localhost/local_ledger_test"},
  migration_timestamps: [type: :naive_datetime_usec],
  queue_target: 1_000,
  queue_interval: 5_000
