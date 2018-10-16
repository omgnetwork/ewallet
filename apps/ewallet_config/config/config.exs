use Mix.Config

config :ewallet_config,
  ecto_repos: [EWalletConfig.Repo],
  env: Mix.env()


import_config "#{Mix.env()}.exs"
