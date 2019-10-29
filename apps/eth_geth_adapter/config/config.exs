use Mix.Config

# Looking for :ethereumex config? See `EthGethAdapter.Application.start/2`.

config :eth_geth_adapter,
  env: Mix.env(),
  settings: [
    :blockchain_json_rpc_url
  ]

import_config "#{Mix.env()}.exs"
