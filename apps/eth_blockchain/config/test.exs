use Mix.Config

config :eth_blockchain,
       EthBlockchain.Adapter,
       adapters: [
         {:dumb, EthBlockchain.DumbAdapter}
       ]

config :eth_blockchain,
  default_adapter: :dumb
