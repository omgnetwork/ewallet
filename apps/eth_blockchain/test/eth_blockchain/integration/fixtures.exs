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

defmodule EthBlockchain.Integration.Fixtures do
  @moduledoc """
  Contains fixtures for tests that require geth
  """
  use ExUnitFixtures.FixtureModule

  alias EthBlockchain.{Adapter, IntegrationHelpers}

  deffixture node_adapter do
    {:ok, datadir} = Briefly.create(directory: true)
    {:ok, exit_fn} = Adapter.call({:boot_adapter, datadir})
    on_exit(exit_fn)
    :ok
  end

  deffixture prepare_env(node_adapter) do
    :ok = node_adapter
    :ok = IntegrationHelpers.prepare_env()
  end

  deffixture entities(prepare_env) do
    :ok = prepare_env
    IntegrationHelpers.entities()
  end

  deffixture(alice(entities), do: entities.alice)
  deffixture(bob(entities), do: entities.bob)
  deffixture(hot_wallet(entities), do: entities.hot_wallet)

  deffixture funded_hot_wallet(hot_wallet) do
    {:ok, _} = IntegrationHelpers.fund_account(hot_wallet.address)
    hot_wallet
  end

  deffixture omg_contract(funded_hot_wallet) do
    {:ok, contract_addr} = IntegrationHelpers.deploy_omg(funded_hot_wallet.address)
    contract_addr
  end
end
