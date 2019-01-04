use Mix.Config

config :ewallet_db, EWalletDB.Repo,
  adapter: Ecto.Adapters.Postgres,
  url: {:system, "DATABASE_URL", "postgres://localhost/ewallet_prod"},
  loggers: [Appsignal.Ecto, Ecto.LogEntry]
