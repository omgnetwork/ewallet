use Mix.Config

config :blockchain_ledger_db, BlockchainLedgerDB.Repo,
  adapter: Ecto.Adapters.Postgres,
  pool: Ecto.Adapters.SQL.Sandbox,
  url: {:system, "DATABASE_URL", "postgres://localhost/blockchain_ledger_db_test"},
  migration_timestamps: [type: :naive_datetime_usec],
  queue_target: 1_000,
  queue_interval: 5_000
