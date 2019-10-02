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

defmodule EWalletDB.TransactionType do
  @moduledoc """
  Determines the type of a transaction from its different fields
  """
  alias EWalletDB.BlockchainWallet

  def get(transaction) do
    rootchain_identifier = Application.get_env(:ewallet_db, :rootchain_identifier)
    %{address: address} = BlockchainWallet.get_primary_hot_wallet(rootchain_identifier)

    case {transaction.from_blockchain_address, transaction.to_blockchain_address,
          transaction.from, transaction.to} do
      {nil, nil, from, to} when not is_nil(from) and not is_nil(to) ->
        :from_ledger_to_ledger

      {from_blockchain, ^address, nil, nil} when not is_nil(from_blockchain) ->
        :from_blockchain_to_ewallet

      {^address, to_blockchain, nil, nil} when not is_nil(to_blockchain) ->
        :from_ewallet_to_blockchain

      {from_blockchain, ^address, nil, to_ledger} when not is_nil(from_blockchain) and not is_nil(to_ledger) ->
        :from_blockchain_to_ledger

      {^address, to_blockchain, from_ledger, nil} when not is_nil(to_blockchain) and not is_nil(from_ledger) ->
        :from_ledger_to_blockchain

      _ ->
        :invalid_type
    end
  end
end
