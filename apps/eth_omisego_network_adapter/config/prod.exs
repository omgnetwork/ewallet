use Mix.Config

config :eth_omisego_network_adapter,
  contract_address:
    {:system, "OMISEGO_NETWORK_CONTRACT_ADDRESS", "0x316d3e9d574e91fd272fd24fb5cb7dfd4707a571"},
  childchain_url: {:system, "OMISEGO_NETWORK_CHILDCHAIN_URL", "http://localhost:9656"},
  watcher_url: {:system, "OMISEGO_NETWORK_WATCHER_URL", "http://localhost:7434"}
