use Mix.Config

config :blockchain_ledger_db,
  ecto_repos: [BlockchainLedgerDB.Repo],
  settings: []

import_config "#{Mix.env()}.exs"
