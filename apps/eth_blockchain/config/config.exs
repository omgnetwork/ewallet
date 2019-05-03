use Mix.Config

config :eth_blockchain,
       EthBlockchain.Adapter,
       adapters: [
         {:geth, EthGethAdapter.Worker}
       ]

config :eth_blockchain,
  default_adapter: :geth

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
