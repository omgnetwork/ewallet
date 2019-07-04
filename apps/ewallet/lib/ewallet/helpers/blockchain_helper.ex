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
  Call the default blockchain adapter with the specifed function spec
  and the default node adapter
  """
  def call(func_name, func_attrs \\ %{}, pid \\ nil) do
    blockchain_adapter = Application.get_env(:ewallet, :blockchain_adapter)
    node_adapter = Application.get_env(:ewallet, :node_adapter)
    blockchain_adapter.call({func_name, func_attrs}, node_adapter, pid)
  end
end
