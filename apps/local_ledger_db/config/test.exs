use Mix.Config

config :local_ledger_db, LocalLedgerDB.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  url: {:system, "LOCAL_LEDGER_DATABASE_URL", "postgres://localhost/local_ledger_test"},
  queue_target: 1_000,
  queue_interval: 5_000
