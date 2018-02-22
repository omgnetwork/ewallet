use Mix.Config

config :ewallet_db,
  ecto_repos: [EWalletDB.Repo],
  env: Mix.env

import_config "#{Mix.env}.exs"

storage_adapter = System.get_env("FILE_STORAGE_ADAPTER") || "local"
case storage_adapter do
  "aws"   -> import_config "adapters/aws.exs"
  "gcs"   -> import_config "adapters/gcs.exs"
  "local" -> import_config "adapters/local.exs"
end
