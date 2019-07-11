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
  Returns the blockchain identifier corresponding to the default adapter
  """
  def identifier do
    adapter().helper().identifier()
  end

  @doc """
  Call the default blockchain adapter with the specifed function spec
  and the default node adapter
  """
  def call(func_name, func_attrs \\ %{}, pid \\ nil) do
    node_adapter = Application.get_env(:ewallet, :node_adapter)
    adapter().call({func_name, func_attrs}, node_adapter, pid)
  end

  @doc """
  Returns the default blockchain adapter
  """
  def adapter do
    Application.get_env(:ewallet_db, :blockchain_adapter)
  end
end
