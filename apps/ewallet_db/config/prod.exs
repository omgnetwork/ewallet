use Mix.Config

config :ewallet_db, EWalletDB.Repo,
  adapter: Ecto.Adapters.Postgres,
  url: System.get_env("DATABASE_URL") || "postgres://localhost/ewallet_prod"

config :ewallet_db,
  base_url: System.get_env("BASE_URL")

key = System.get_env("EWALLET_SECRET_KEY")

config :cloak, Salty.SecretBox.Cloak,
       tag: "SBX",
       default: true,
       keys: [%{tag: <<1>>, key: key, default: true}]

config :ewallet_db, EWalletDB.Scheduler,
  jobs: [
    {"* * * * *", {EWalletDB.TransactionRequest, :expire_all, []}},
    {"* * * * *", {EWalletDB.TransactionConsumption, :expire_all, []}}
  ]
