use Mix.Config

config :eth_blockchain,
       EthBlockchain.Adapter,
       adapters: [
         {:dumb, EthBlockchain.DumbAdapter},
         {:dumb_receiver, EthBlockchain.DumbReceivingAdapter}
       ],
       default_adapter: :dumb

config :eth_blockchain,
  transaction_poll_interval: 100
