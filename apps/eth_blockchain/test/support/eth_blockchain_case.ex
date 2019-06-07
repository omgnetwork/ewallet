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

defmodule EthBlockchain.EthBlockchainCase do
  @moduledoc false
  use ExUnit.CaseTemplate
  alias EthBlockchain.{Adapter, DumbAdapter}
  alias Ecto.UUID

  using do
    quote do
      import EthBlockchain.EthBlockchainCase
    end
  end

  setup do
    supervisor = String.to_atom("#{UUID.generate()}")

    {:ok, _} =
      DynamicSupervisor.start_link(
        name: supervisor,
        strategy: :one_for_one
      )

    {:ok, pid} =
      Adapter.start_link(
        supervisor: supervisor,
        adapters: [
          {:dumb, DumbAdapter}
        ]
      )

    %{
      pid: pid,
      supervisor: supervisor,
      addr_0: "0x0000000000000000000000000000000000000000",
      addr_1: "0x0000000000000000000000000000000000000001",
      addr_2: "0x0000000000000000000000000000000000000002",
      addr_3: "0x0000000000000000000000000000000000000003"
    }
  end
end
