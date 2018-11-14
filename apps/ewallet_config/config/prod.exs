use Mix.Config

config :ewallet_config, EWalletConfig.Repo,
  adapter: Ecto.Adapters.Postgres,
  url: {:system, "DATABASE_URL", "postgres://localhost/ewallet_prod"}
