use Mix.Config

config :eth_blockchain,
       EthBlockchain.Adapter,
       eth_node_adapters: [
         {:geth, EthGethAdapter.Worker}
       ],
       cc_node_adapters: [
         {:omisego_network, EthOmisegoNetworkAdapter.Worker}
       ],
       default_eth_node_adapter: :geth,
       default_cc_node_adapter: :omisego_network,
       default_eth_test_integration_adapter: :geth

config :eth_blockchain,
  default_gas_price: 20_000_000_000,
  default_eth_transaction_gas_limit: 21_000,
  default_contract_transaction_gas_limit: 90_000,
  default_contract_creation_gas_limit: 1_500_000,
  child_chain_deposit_eth_gas_limit: 180_000,
  child_chain_deposit_token_gas_limit: 250_000,
  # Custom id used for development/testing only, to be updated for production use
  chain_id: 1337,
  transaction_poll_interval: 5000

config :eth_blockchain,
  default_gas_price: 20_000_000_000

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
