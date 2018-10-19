use Mix.Config

audits = %{
  EWalletConfig.System => "system",
  EWalletDB.User => "user",
  EWalletDB.Invite => "invite",
  EWalletDB.Key => "key",
  EWalletDB.ForgetPasswordRequest => "forget_password_request"
}

config :ewallet_db,
  ecto_repos: [EWalletDB.Repo],
  env: Mix.env(),
  schemas_to_audit_types: audits,
  audit_types_to_schemas: Enum.into(audits, %{}, fn {key, value} -> {value, key} end),
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
