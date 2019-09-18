# Copyright 2019 OmiseGO Pte Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule EthBlockchain.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec
    DeferredConfig.populate(:eth_blockchain)

    config = Application.get_env(:eth_blockchain, EthBlockchain.Adapter)
    eth_node_adapters = Keyword.get(config, :eth_node_adapters)
    cc_node_adapters = Keyword.get(config, :cc_node_adapters)

    adapter_opts = [
      adapters: eth_node_adapters ++ cc_node_adapters,
      named: true,
      supervisor: EthBlockchain.DynamicSupervisor
    ]

    children = [
      worker(EthBlockchain.AdapterServer, [adapter_opts]),
      {DynamicSupervisor, name: EthBlockchain.DynamicSupervisor, strategy: :one_for_one},
      {DynamicSupervisor, name: EthBlockchain.DynamicListenerSupervisor, strategy: :one_for_one},
      {DynamicSupervisor, name: EthBlockchain.DynamicNonceSupervisor, strategy: :one_for_one},
      {EthBlockchain.BlockchainRegistry,
       name: EthBlockchain.BlockchainRegistry, strategy: :one_for_one},
      {EthBlockchain.NonceRegistry, name: EthBlockchain.NonceRegistry, strategy: :one_for_one}
    ]

    # We want to restart DynamicSupervisor when EthBlockchain.Adapter crashes
    # so we don't ended up with inconsistent state where EthBlockchain.Adapter
    # has no adapters in its registry, but DynamicSupervisor already has them
    # running.
    #
    # Using :one_for_all ensures that DynamicSupervisor will be restarted.
    # You can use `DynamicSupervisor.which_children(EthBlockchain.DynamicSupervisor)`
    # to check whether there's a zombie process running after crashes.
    #
    opts = [strategy: :one_for_all, name: EthBlockchain.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
