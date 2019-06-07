use Mix.Config

config :eth_blockchain,
       EthBlockchain.Adapter,
       adapters: [
         {:geth, EthGethAdapter.Worker}
       ],
       default_adapter: :geth

config :eth_blockchain,
  default_gas_price: 20_000_000_000,
  default_eth_transaction_gas_limit: 21_000,
  default_contract_transaction_gas_limit: 42_000,
  chain_id: 1

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
