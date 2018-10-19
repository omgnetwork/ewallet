use Mix.Config

config :ewallet_config,
  ecto_repos: [EWalletConfig.Repo]

import_config "#{Mix.env()}.exs"
