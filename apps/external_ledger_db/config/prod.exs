use Mix.Config

config :external_ledger_db, ExternalLedgerDB.Repo,
  adapter: Ecto.Adapters.Postgres,
  url: {:system, "EXTERNAL_LEDGER_DATABASE_URL", "postgres://localhost/external_ledger"},
  migration_timestamps: [type: :naive_datetime_usec]

config :ethereumex,
  url: {:system, "ETHEREUM_NODE_URL", "http://localhost:8545"},
  http_options: [timeout: 8000, recv_timeout: 5000]
