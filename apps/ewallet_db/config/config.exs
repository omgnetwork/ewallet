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
    :gcs_credentials,
    :master_account
  ]

config :ewallet_db, EWalletDB.Repo,
  adapter: Ecto.Adapters.Postgres,
  pool: DB.SharedConnectionPool,
  pool_size: {:system, "EWALLET_POOL_SIZE", 15, {String, :to_integer}},
  shared_pool_id: :ewallet,
  migration_timestamps: [type: :naive_datetime_usec]

import_config "#{Mix.env()}.exs"
