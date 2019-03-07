use Mix.Config

config :status,
  metrics: true

import_config "#{Mix.env()}.exs"
