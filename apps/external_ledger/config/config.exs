use Mix.Config

config :external_ledger,
  ecto_repos: [ExternalLedger.Repo],
  settings: []

import_config "#{Mix.env()}.exs"
