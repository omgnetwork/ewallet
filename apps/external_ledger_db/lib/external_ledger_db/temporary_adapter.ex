# Copyright 2017-2019 OmiseGO Pte Ltd
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

defmodule ExternalLedgerDB.TemporaryAdapter do
  @moduledoc """
  The TempoarayAdapter to be replaced by #693.
  """
  alias ExternalLedgerDB.TemporaryAdapter.Token

  @ethereum "ethereum"
  @omg_network "omg_network"
  @adapters [@ethereum, @omg_network]

  def adapters, do: @adapters

  def valid_adapter?(adapter) do
    adapter in @adapters
  end

  defdelegate fetch_token(contract_address, adapter), to: Token, as: :fetch
end
