use Mix.Config

config :local_ledger_db, LocalLedgerDB.Repo,
  adapter: Ecto.Adapters.Postgres,
  pool: Ecto.Adapters.SQL.Sandbox,
  url: {:system, "LOCAL_LEDGER_DATABASE_URL", "postgres://localhost/local_ledger_test"}
