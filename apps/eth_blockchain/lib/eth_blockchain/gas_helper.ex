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

defmodule EthBlockchain.GasHelper do
  @moduledoc """
  Helper functions to operate with gas limit and gas price.
  """

  #
  # Gas limit
  #

  def get_gas_limit_or_default(_type, %{gas_limit: gas_limit}), do: gas_limit

  def get_gas_limit_or_default(type, _attrs) do
    get_default_gas_limit(type)
  end

  def get_default_gas_limit(type) do
    :eth_blockchain
    |> Application.get_env(:gas_limit)
    |> Keyword.get(type)
  end

  #
  # Gas prices
  #

  def get_gas_price_or_default(%{gas_price: gas_price}), do: gas_price

  def get_gas_price_or_default(_attrs), do: get_default_gas_price()

  def get_default_gas_price do
    Application.get_env(:eth_blockchain, :blockchain_default_gas_price)
  end
end
