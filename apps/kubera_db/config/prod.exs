use Mix.Config

config :kubera_db, KuberaDB.Repo,
  adapter: Ecto.Adapters.Postgres,
  url: System.get_env("DATABASE_URL") || "postgres://localhost/kubera_prod"
