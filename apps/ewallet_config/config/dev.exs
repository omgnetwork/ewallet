use Mix.Config

config :ewallet_config, EWalletConfig.Repo,
  url: {:system, "DATABASE_URL", "postgres://localhost/ewallet_dev"}
