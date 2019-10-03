use Mix.Config

config :ewallet,
  websocket_endpoints: [EWallet.TestEndpoint],
  eth_node_adapter: {:dumb, EthGethAdapter.DumbAdapter},
  cc_node_adapter: {:dumb_cc, EthGethAdapter.DumbCCAdapter},
  # Pooling will cause side effects that impact balances during tests, so let's disable it.
  deposit_pooling_interval: 0
