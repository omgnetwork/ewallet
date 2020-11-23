ExUnit.start()
DeferredConfig.populate(:eth_omisego_adapter)

children = [
  {Plug.Cowboy, scheme: :http, plug: EthOmiseGOAdapter.MockServer, options: [port: 8081]}
]

opts = [strategy: :one_for_one, name: EthOmiseGOAdapter.MockSupervisor]
{:ok, _pid} = Supervisor.start_link(children, opts)
