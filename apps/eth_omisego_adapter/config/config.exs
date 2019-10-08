use Mix.Config

config :eth_omisego_adapter,
  settings: [
    :omisego_rootchain_contract_address,
    :omisego_watcher_url,
    :omisego_childchain_url
  ]

import_config "#{Mix.env()}.exs"
