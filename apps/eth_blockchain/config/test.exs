use Mix.Config

config :eth_blockchain,
       EthBlockchain.Adapter,
       adapters: [
         {:dumb, EthBlockchain.DumbAdapter}
       ],
       default_adapter: :dumb
