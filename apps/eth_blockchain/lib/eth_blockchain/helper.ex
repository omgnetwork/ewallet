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

defmodule EthBlockchain.Helper do
  @moduledoc false

  @token_address "0x0000000000000000000000000000000000000000"
  @token_symbol "ETH"
  @token_name "Ether"
  @token_subunit_to_unit 1_000_000_000_000_000_000

  def identifier, do: "ethereum"

  def adapter_address?("0x" <> _ = address)
      when is_binary(address) and byte_size(address) == 42,
      do: true

  def adapter_address?(_address), do: false
  def default_address, do: @token_address

  @doc """
  Returns a map containing the attributes of the Ethereum token
  """
  def default_token do
    %{
      symbol: @token_symbol,
      name: @token_name,
      address: @token_address,
      subunit_to_unit: @token_subunit_to_unit
    }
  end
end
