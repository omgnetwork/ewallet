use Mix.Config

config :local_ledger_db, LocalLedgerDB.Repo,
  url: {:system, "LOCAL_LEDGER_DATABASE_URL", "postgres://localhost/local_ledger_prod"}
