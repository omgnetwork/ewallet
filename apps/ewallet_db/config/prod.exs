use Mix.Config

config :ewallet_db, EWalletDB.Repo,
  adapter: Ecto.Adapters.Postgres,
  url: System.get_env("DATABASE_URL") || "postgres://localhost/ewallet_prod"

config :ewallet_db,
  # Replace this with unified domain name
  host: System.get_env("UPLOADS_BASE_URL")

key = System.get_env("EWALLET_SECRET_KEY")

config :cloak, Salty.SecretBox.Cloak,
       tag: "SBX",
       default: true,
       keys: [%{tag: <<1>>, key: key, default: true}]
