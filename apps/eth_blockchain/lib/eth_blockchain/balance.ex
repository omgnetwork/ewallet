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

defmodule EthBlockchain.Balance do
  @moduledoc false

  alias EthBlockchain.Adapter

  @doc """
  Retrieve the balance of all given `contract_addresses` for the provided wallet `address`.
  The contract address `0x0000000000000000000000000000000000000000` is handled as
  the ethereum token and so the ethereum balance will be retrieved.
  Any other given contract address will have their balance retrived on the corresponding
  smart contract.

  Returns a tuple of
  ```
  {
    :ok,
    %{
      "contract_address_1" => integer_balance_1,
      "contract_address_2" => integer_balance_2
    }
  }
  ```
  if successful or {:error, error_code} if failed.
  """
  def get(params, adapter \\ Application.get_env(:eth_blockchain, :default_adapter), pid \\ nil)

  def get({address, contract_addresses}, adapter, pid) do
    get({address, contract_addresses, "latest"}, adapter, pid)
  end

  def get({address, contract_addresses, block}, adapter, pid) do
    case pid do
      nil ->
        Adapter.call(adapter, {:get_balances, address, contract_addresses, block})

      p when is_pid(p) ->
        Adapter.call(adapter, {:get_balances, address, contract_addresses, block}, p)
    end
  end
end
