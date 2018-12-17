use Mix.Config

config :ewallet_db,
  ecto_repos: [EWalletDB.Repo],
  env: Mix.env(),
  settings: [
    :base_url,
    :min_password_length,
    :file_storage_adapter,
    :aws_bucket,
    :aws_region,
    :aws_access_key_id,
    :aws_secret_access_key,
    :gcs_bucket,
    :gcs_credentials
  ]

import_config "#{Mix.env()}.exs"
