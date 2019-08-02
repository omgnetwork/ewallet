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

defmodule EthBlockchain.EthBlockchainIntegrationCase do
  @moduledoc false
  use ExUnit.CaseTemplate

  alias Ecto.Adapters.SQL.Sandbox
  alias Keychain.Repo

  using do
    quote do
      import EthBlockchain.EthBlockchainIntegrationCase
    end
  end

  setup tags do
    :ok = Sandbox.checkout(Repo)

    unless tags[:async] do
      Sandbox.mode(Repo, {:shared, self()})
    end

    original_env = Application.get_env(:eth_blockchain, EthBlockchain.Adapter)
    default_integration_adapter = Keyword.get(original_env, :default_test_integration_adapter)
    updated_env = Keyword.put(original_env, :default_adapter, default_integration_adapter)

    Application.put_env(:eth_blockchain, EthBlockchain.Adapter, updated_env)

    on_exit(fn ->
      Application.put_env(:eth_blockchain, EthBlockchain.Adapter, original_env)
    end)

    tags
  end
end
