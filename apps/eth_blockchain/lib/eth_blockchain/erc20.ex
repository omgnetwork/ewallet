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

defmodule EthBlockchain.ERC20 do
  @moduledoc false

  import Utils.Helpers.Encoding

  def abi_balance_of(address) when byte_size(address) == 42 do
    {:ok, contract_call_data("balanceOf(address)", [from_hex(address)])}
  end

  def abi_balance_of(_address), do: {:error, :invalid_address}

  def abi_transfer_from(from_address, to_address, amount)
      when byte_size(from_address) == 42 and byte_size(to_address) == 42 and is_integer(amount) do
    {:ok,
     contract_call_data("transferFrom(address,address,uint)", [
       from_hex(from_address),
       from_hex(to_address),
       amount
     ])}
  end

  def abi_transfer_from(_from_address, _to_address, _amount), do: {:error, :invalid_input}

  defp contract_call_data(signature, args) do
    signature |> ABI.encode(args) |> to_hex()
  end
end
