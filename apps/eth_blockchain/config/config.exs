use Mix.Config

config :eth_blockchain,
       EthBlockchain.Adapter,
       adapters: [
         {:geth, EthGethAdapter.Worker}
       ],
       childchains: [
         elixir_omg: %{
           contract_address: {:system, "ELIXIR_OMG_CONTRACT_ADDRESS"},
           childchain_url: {:system, "ELIXIR_OMG_CHILDCHAIN_URL"},
           watcher_url: {:system, "ELIXIR_OMG_WATCHER_URL"}
           adapter: {:elixir_omg, ElixirOMGAdapter.Worker}
         }
       ],
       default_adapter: :geth,
       default_child_adapter: :elixir_omg,

config :eth_blockchain,
  default_gas_price: 20_000_000_000,
  default_eth_transaction_gas_limit: 21_000,
  default_contract_transaction_gas_limit: 90_000,
  default_contract_creation_gas_limit: 1_500_000,
  # Custom id used for development/testing only, to be updated for production use
  chain_id: 90_325,
  transaction_poll_interval: 5000

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
