use Mix.Config

config :kubera_db, ecto_repos: [KuberaDB.Repo]

import_config "#{Mix.env}.exs"
