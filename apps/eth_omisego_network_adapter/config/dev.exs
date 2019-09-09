use Mix.Config

config :eth_omisego_network_adapter,
  contract_address:
    {:system, "OMISEGO_NETWORK_CONTRACT_ADDRESS", "0xc41e99cb6cfa8fd7fd42b0aaddb541326593bdc8"},
  childchain_url: {:system, "OMISEGO_NETWORK_CHILDCHAIN_URL", "http://localhost:9656"},
  watcher_url: {:system, "OMISEGO_NETWORK_WATCHER_URL", "http://localhost:7434"}
