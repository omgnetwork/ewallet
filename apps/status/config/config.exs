use Mix.Config

config :status,
  metrics: {:system, "METRICS", false}

import_config "#{Mix.env()}.exs"
