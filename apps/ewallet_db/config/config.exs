use Mix.Config

audits = %{
  EWalletDB.System => "system",
  EWalletDB.User => "user",
  EWalletDB.Invite => "invite"
}

config :ewallet_db,
  ecto_repos: [EWalletDB.Repo],
  env: Mix.env(),
  base_url: {:system, "BASE_URL", "http://localhost:4000"},
  min_password_length: 8,
  schemas_to_audit_types: audits,
  audit_types_to_schemas:
    audits
    |> Enum.map(fn {key, value} -> {value, key} end)
    |> Enum.into(%{})

import_config "#{Mix.env()}.exs"
