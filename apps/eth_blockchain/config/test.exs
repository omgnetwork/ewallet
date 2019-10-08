use Mix.Config

config :eth_blockchain,
       EthBlockchain.Adapter,
       eth_node_adapters: [
         {:dumb, EthBlockchain.DumbAdapter},
         {:dumb_receiver, EthBlockchain.DumbReceivingAdapter}
       ],
       cc_node_adapters: [
         {:dumb_cc, EthBlockchain.DumbCCAdapter}
       ],
       default_eth_node_adapter: :dumb,
       default_cc_node_adapter: :dumb_cc
