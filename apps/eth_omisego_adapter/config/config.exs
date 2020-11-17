use Mix.Config

config :eth_omisego_adapter,
  settings: [
    :omisego_plasma_framework_address,
    :omisego_eth_vault_address,
    :omisego_erc20_vault_address,
    :omisego_payment_exit_game_address,
    :omisego_watcher_url,
    :omisego_childchain_url
  ]

import_config "#{Mix.env()}.exs"
