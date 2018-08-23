use Mix.Config

config :ewallet,
  redirect_url_prefixes: "http://localhost:4000",
  websocket_endpoints: [
    EWallet.TestEndpoint,
    EWalletAPI.V1.Endpoint,
    AdminAPI.V1.Endpoint
  ]

# Configs for Bamboo emailing library
config :ewallet, EWallet.Mailer, adapter: Bamboo.TestAdapter
