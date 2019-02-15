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

defmodule Blockchain.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    backends =
      :blockchain
      |> Application.get_env(Blockchain.Backend)
      |> Keyword.get(:backends)

    children = [
      worker(Blockchain.Backend, [[backends: backends]]),
      {DynamicSupervisor, name: Blockchain.DynamicSupervisor, strategy: :one_for_one}
    ]

    # We want to restart DynamicSupervisor when Blockchain.Backend crashes
    # so we don't ended up with inconsistent state where Blockchain.Backend
    # has no backends in its registry, but DynamicSupervisor already has them
    # running.
    #
    # Using :one_for_all ensures that DynamicSupervisor will be restarted.
    # You can use `DynamicSupervisor.which_children(Blockchain.DynamicSupervisor)`
    # to check whether there's a zombie process running after crashes.
    #
    opts = [strategy: :one_for_all, name: Blockchain.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
