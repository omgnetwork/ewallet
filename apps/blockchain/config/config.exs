use Mix.Config

config :blockchain,
       Blockchain.Backend,
       backends: [
         {:eth, BlockchainEth.Worker}
       ]
