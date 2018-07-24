use Mix.Config

config :ewallet_db, EWalletDB.Repo,
  adapter: Ecto.Adapters.Postgres,
  url: {:system, "DATABASE_URL", "postgres://localhost/ewallet_prod"}

config :ewallet_db, base_url: {:system, "BASE_URL"}
