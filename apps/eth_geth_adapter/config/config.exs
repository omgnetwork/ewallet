use Mix.Config

config :eth_geth_adapter,
  env: Mix.env()

import_config "#{Mix.env()}.exs"
