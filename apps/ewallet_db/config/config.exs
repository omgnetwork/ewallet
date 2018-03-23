use Mix.Config

config :ewallet_db,
  ecto_repos: [EWalletDB.Repo],
  env: Mix.env,
  base_url: System.get_env("BASE_URL") || "http://localhost:4000",
  jobs: [
    {"* * * * *",      {EWalletDB.TransactionRequest, :expire_all, []}},
    {"* * * * *",      {EWalletDB.TransactionConsumption, :expire_all, []}},
  ]

import_config "#{Mix.env}.exs"

storage_adapter = System.get_env("FILE_STORAGE_ADAPTER") || "local"
case storage_adapter do
  "aws"   -> import_config "adapters/aws.exs"
  "gcs"   -> import_config "adapters/gcs.exs"
  "local" -> import_config "adapters/local.exs"
end
