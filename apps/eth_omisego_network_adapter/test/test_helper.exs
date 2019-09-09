ExUnit.start()
DeferredConfig.populate(:eth_omisego_network_adapter)

children = [
  {Plug.Cowboy, scheme: :http, plug: EthOmisegoNetworkAdapter.MockServer, options: [port: 8081]}
]

opts = [strategy: :one_for_one, name: EthOmisegoNetworkAdapter.Supervisor]
{:ok, _pid} = Supervisor.start_link(children, opts)
