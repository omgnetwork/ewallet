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
  default_contract_transaction_gas_limit: 90_000,
  default_contract_creation_gas_limit: 1_500_000,
  child_chain_deposit_eth_gas_limit: 180_000,
  child_chain_deposit_token_gas_limit: 250_000,
  # Custom id used for development/testing only, to be updated for production use
  chain_id: 1337,
  transaction_poll_interval: 5000,
  childchains: %{
    "elixir_omg" => %{
      contract_address:
        {:system, "ELIXIR_OMG_CONTRACT_ADDRESS", "0xd99d842b31c06e31d455f339c57b6c3d1860af39"},
      childchain_url: {:system, "ELIXIR_OMG_CHILDCHAIN_URL", "http://localhost:7434"},
      watcher_url: {:system, "ELIXIR_OMG_WATCHER_URL", "http://localhost:9656"},
      adapter: {:elixir_omg, ElixirOMGAdapter.Worker}
    }
  },
  default_childchain: "elixir_omg"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
