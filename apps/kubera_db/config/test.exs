use Mix.Config

config :kubera_db, KuberaDB.Repo,
  adapter: Ecto.Adapters.Postgres,
  pool: Ecto.Adapters.SQL.Sandbox,
  url: System.get_env("DATABASE_URL") || "postgres://localhost/kubera_test"

# Uncomment this line to hide database requests when running tests
config :logger, level: :warn
