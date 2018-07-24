use Mix.Config

config :ewallet_db, EWalletDB.Repo,
  adapter: Ecto.Adapters.Postgres,
  pool: Ecto.Adapters.SQL.Sandbox,
  url: {:system, "DATABASE_URL", "postgres://localhost/ewallet_test"}
