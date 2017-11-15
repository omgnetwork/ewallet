use Mix.Config

config :kubera_db, KuberaDB.Repo,
  adapter: Ecto.Adapters.Postgres,
  url: System.get_env("DATABASE_URL") || "postgres://localhost/kubera_dev"

key = "j6fy7rZP9ASvf1bmywWGRjrmh8gKANrg40yWZ-rSKpI"

config :cloak, Salty.SecretBox.Cloak,
       tag: "SBX",
       default: true,
       keys: [%{tag: <<1>>, key: key, default: true}]
