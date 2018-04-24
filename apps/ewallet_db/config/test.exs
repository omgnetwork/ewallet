use Mix.Config

config :ewallet_db, EWalletDB.Repo,
  adapter: Ecto.Adapters.Postgres,
  pool: Ecto.Adapters.SQL.Sandbox,
  url: System.get_env("DATABASE_URL") || "postgres://localhost/ewallet_test"

key = "j6fy7rZP9ASvf1bmywWGRjrmh8gKANrg40yWZ-rSKpI"

config :cloak, Salty.SecretBox.Cloak,
  tag: "SBX",
  default: true,
  keys: [%{tag: <<1>>, key: key, default: true}]
