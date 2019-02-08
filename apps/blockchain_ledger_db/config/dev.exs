use Mix.Config

config :blockchain_ledger_db, BlockchainLedgerDB.Repo,
  adapter: Ecto.Adapters.Postgres,
  url: {:system, "DATABASE_URL", "postgres://localhost/blockchain_ledger_db_dev"},
  migration_timestamps: [type: :naive_datetime_usec]
