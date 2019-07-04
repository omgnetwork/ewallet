use Mix.Config

config :eth_blockchain,
       EthBlockchain.Adapter,
       adapters: [
         {:dumb, EthBlockchain.DumbAdapter}
       ],
       default_adapter: :dumb

config :eth_blockchain,
  transaction_poll_interval: 100
