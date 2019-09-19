# Copyright 2018-2019 OmiseGO Pte Ltd
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

defmodule EWallet.BlockchainHelper do
  @moduledoc """
  The module for blockchain helpers.
  """

  @doc """
  Returns the main rootchain identifier
  """
  def rootchain_identifier do
    Application.get_env(:ewallet_db, :rootchain_identifier)
  end

  @doc """
  Returns the main childchain identifier
  """
  def childchain_identifier do
    Application.get_env(:ewallet_db, :childchain_identifier)
  end

  @doc """
  Returns :ok if the given address is a valid blockchain address
  for the current adapter or {:error, :invalid_blockchain_address} otherwise.
  """
  def validate_blockchain_address(address) do
    case adapter().helper().adapter_address?(address) do
      true -> :ok
      false -> {:error, :invalid_blockchain_address}
    end
  end

  @doc """
  Returns :ok if the given identifier is supported by the system
  or {:error, :blockchain_invalid_identifier} otherwise.
  """
  def validate_identifier(identifier) do
    case identifier in [rootchain_identifier(), childchain_identifier()] do
      true -> :ok
      false -> {:error, :blockchain_invalid_identifier}
    end
  end

  @doc """
  Call the default blockchain adapter with the specifed function spec
  and the default node adapter
  """
  def call(func_name, func_attrs \\ %{}, opts \\ []) do
    opts =
      opts
      |> Keyword.put_new(:eth_node_adapter, Application.get_env(:ewallet, :eth_node_adapter))
      |> Keyword.put_new(:cc_node_adapter, Application.get_env(:ewallet, :cc_node_adapter))

    adapter().call({func_name, func_attrs}, opts)
  end

  @doc """
  Returns the default blockchain adapter
  """
  def adapter do
    Application.get_env(:ewallet_db, :blockchain_adapter)
  end

  def invalid_erc20_contract_address do
    adapter().dumb_adapter.invalid_erc20_contract_address()
  end
end
