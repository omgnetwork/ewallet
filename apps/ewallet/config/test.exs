use Mix.Config

config :ewallet,
  websocket_endpoints: [EWallet.TestEndpoint],
  queue_target: 1_000,
  queue_interval: 5_000
