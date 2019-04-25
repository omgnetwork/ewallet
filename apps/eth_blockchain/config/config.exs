use Mix.Config

config :eth_blockchain,
       EthBlockchain.Backend,
       backends: [
         {:eth, EthGethAdapter.Worker}
       ]
