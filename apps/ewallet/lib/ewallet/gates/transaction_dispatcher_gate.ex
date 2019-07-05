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

defmodule EWallet.TransactionDispatcherGate do
  @moduledoc """
  Handles the logic for a transaction of value from an account to a user. Delegates the
  actual transaction to EWallet.LocalTransactionGate once the wallets have been loaded.
  """
  alias EWallet.{
    LocalTransactionGate,
    BlockchainTransactionGate
  }

  def create(actor, %{"from_address" => from, "to_address" => to} = attrs) do
    case BlockchainTransactionGate.blockchain_addresses?([from, to]) do
      [false, false] ->
        LocalTransactionGate.create(actor, attrs)

      blockchain_addresses ->
        BlockchainTransactionGate.create(actor, attrs, blockchain_addresses)
    end
  end
end
