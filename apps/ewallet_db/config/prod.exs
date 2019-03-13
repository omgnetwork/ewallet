use Mix.Config

config :ewallet_db, EWalletDB.Repo,
  url: {:system, "DATABASE_URL", "postgres://localhost/ewallet_prod"}
