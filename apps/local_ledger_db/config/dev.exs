use Mix.Config

config :local_ledger_db, LocalLedgerDB.Repo,
  adapter: Ecto.Adapters.Postgres,
  url: {:system, "LOCAL_LEDGER_DATABASE_URL", "postgres://localhost/local_ledger_dev"},
  loggers: [Appsignal.Ecto, Ecto.LogEntry]
