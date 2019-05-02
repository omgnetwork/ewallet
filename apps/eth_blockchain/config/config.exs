use Mix.Config

config :eth_blockchain,
       EthBlockchain.Adapter,
       adapters: [
         {:geth, EthGethAdapter.Worker}
       ]
