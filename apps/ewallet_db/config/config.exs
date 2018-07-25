use Mix.Config

config :ewallet_db,
  ecto_repos: [EWalletDB.Repo],
  env: Mix.env(),
  base_url: {:system, "BASE_URL", "http://localhost:4000"},
  min_password_length: 8

import_config "#{Mix.env()}.exs"
