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
  import Utils.Helpers.Encoding

  alias EthBlockchain.{Adapter, ABIEncoder}

  @doc """
  Retrieve the balance of all given `contract_addresses` for the provided wallet `address`.
  Ether is represented with `0x0000000000000000000000000000000000000000` as contract address.
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
  def get(attrs, adapter \\ nil, pid \\ nil)

  def get(%{block: _} = attrs, adapter, pid) do
    do_get(attrs, adapter, pid)
  end

  def get(attrs, adapter, pid) do
    attrs
    |> Map.put(:block, "latest")
    |> do_get(adapter, pid)
  end

  defp do_get(
         %{address: address, contract_addresses: contract_addresses, block: block},
         adapter,
         pid
       ) do
    case ABIEncoder.balance_of(address) do
      {:ok, encoded_abi_data} ->
        Adapter.call(
          {:get_balances, address, contract_addresses, to_hex(encoded_abi_data), block},
          adapter,
          pid
        )

      error ->
        error
    end
  end
end
