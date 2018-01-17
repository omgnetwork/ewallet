use Mix.Config

config :ewallet_db, ecto_repos: [EWalletDB.Repo]

import_config "#{Mix.env}.exs"
