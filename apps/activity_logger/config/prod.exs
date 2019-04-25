use Mix.Config

config :activity_logger, ActivityLogger.Repo,
  url: {:system, "DATABASE_URL", "postgres://localhost/ewallet_prod"}
