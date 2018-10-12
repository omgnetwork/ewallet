use Mix.Config

audits = %{
  EWalletDB.System => "system",
  EWalletDB.User => "user",
  EWalletDB.Invite => "invite",
  EWalletDB.Key => "key",
  EWalletDB.ForgetPasswordRequest => "forget_password_request"
}

config :ewallet_db,
  ecto_repos: [EWalletDB.Repo],
  env: Mix.env(),
  schemas_to_audit_types: audits,
  audit_types_to_schemas: Enum.into(audits, %{}, fn {key, value} -> {value, key} end)

import_config "#{Mix.env()}.exs"
