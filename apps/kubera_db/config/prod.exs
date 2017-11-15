use Mix.Config

config :kubera_db, KuberaDB.Repo,
  adapter: Ecto.Adapters.Postgres,
  url: System.get_env("DATABASE_URL") || "postgres://localhost/kubera_prod"

key = System.get_env("KUBERA_SECRET_KEY")

config :cloak, Salty.SecretBox.Cloak,
       tag: "SBX",
       default: true,
       keys: [%{tag: <<1>>, key: key, default: true}]
