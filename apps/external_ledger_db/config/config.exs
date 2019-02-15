use Mix.Config

config :external_ledger_db,
  ecto_repos: [ExternalLedgerDB.Repo],
  settings: []

config :ethereumex,
  url: {:system, "ETHEREUM_NODE_URL", "http://localhost:8545"}

import_config "#{Mix.env()}.exs"
