use Mix.Config

config :eth_blockchain,
       EthBlockchain.Adapter,
       adapters: [
         {:dumb, EthGethAdapter.DumbAdapter}
       ]

config :eth_blockchain,
  default_adapter: :dumb
