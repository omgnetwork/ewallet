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

defmodule EthBlockchain.ABIEncoder do
  @moduledoc false

  import Utils.Helpers.Encoding

  def balance_of("0x" <> _ = address) do
    {:ok, ABI.encode("balanceOf(address)", [from_hex(address)])}
  end

  def balance_of(_address), do: {:error, :invalid_address}

  @spec transfer(any, any) :: {:error, :invalid_input} | {:ok, binary}
  def transfer("0x" <> _ = to_address, amount) when is_integer(amount) do
    {:ok,
     ABI.encode("transfer(address,uint)", [
       from_hex(to_address),
       amount
     ])}
  end

  def transfer(_to_address, _amount), do: {:error, :invalid_input}
end
