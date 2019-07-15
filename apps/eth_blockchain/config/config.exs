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
  default_contract_creation_gas_limit: 1_000_000,
  # Custom id used for development/testing only, to be updated for production use
  chain_id: 90_325,
  transaction_poll_interval: 5000,
  erc20_bin_file_path: "apps/eth_blockchain/contracts/ERC20/EWalletERC20.bin"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
