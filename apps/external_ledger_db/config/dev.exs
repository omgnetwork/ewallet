use Mix.Config

config :external_ledger_db, ExternalLedgerDB.Repo,
  adapter: Ecto.Adapters.Postgres,
  url: {:system, "EXTERNAL_LEDGER_DATABASE_URL", "postgres://localhost/external_ledger_dev"},
  migration_timestamps: [type: :naive_datetime_usec]
