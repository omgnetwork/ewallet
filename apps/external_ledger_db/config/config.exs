use Mix.Config

config :external_ledger_db,
  ecto_repos: [ExternalLedgerDB.Repo],
  settings: []

import_config "#{Mix.env()}.exs"
