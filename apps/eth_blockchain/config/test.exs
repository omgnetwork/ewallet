use Mix.Config

config :eth_blockchain,
       EthBlockchain.Adapter,
       eth_node_adapters: [
         {:dumb, EthBlockchain.DumbAdapter},
         {:dumb_receiver, EthBlockchain.DumbReceivingAdapter}
       ],
       default_eth_node_adapter: :dumb

config :eth_blockchain,
  transaction_poll_interval: 100
