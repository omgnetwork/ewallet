use Mix.Config

config :eth_blockchain,
  transaction_registry: EthBlockchain.BlockchainRegistry,
  settings: [
    :blockchain_chain_id,
    :blockchain_transaction_poll_interval,
    :blockchain_default_gas_price
  ]

config :eth_blockchain,
       EthBlockchain.Adapter,
       eth_node_adapters: [
         {:geth, EthGethAdapter.Worker}
       ],
       cc_node_adapters: [
         {:omisego_network, EthOmiseGOAdapter.Worker}
       ],
       default_eth_node_adapter: :geth,
       default_cc_node_adapter: :omisego_network,
       default_eth_test_integration_adapter: :geth

config :eth_blockchain,
       :gas_limit,
       eth_transaction: 21_000,
       contract_transaction: 90_000,
       contract_creation: 1_500_000,
       child_chain_deposit_eth: 180_000,
       child_chain_deposit_token: 250_000

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
