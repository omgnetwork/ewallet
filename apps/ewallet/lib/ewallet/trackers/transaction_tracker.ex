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

defmodule EWallet.TransactionTracker do
  @moduledoc """

  """
  @behaviour EWallet.BlockchainTransactionTrackerBehaviour

  alias EWallet.{
    BlockchainTransactionTracker,
    TransactionGate
  }

  alias EWalletDB.Helpers.Preloader

  alias EWalletDB.{Transaction}

  def start_all_pending() do
    # TODO: Query all pending and start for each
  end

  def start(blockchain_transaction) do
    BlockchainTransactionTracker.start(blockchain_transaction, __MODULE__)
  end

  @impl EWallet.BlockchainTransactionTrackerBehaviour
  def on_confirmed(blockchain_transaction) do
    [blockchain_transaction_uuid: blockchain_transaction.uuid]
    |> Transaction.get_by()
    |> Preloader.preload(:blockchain_transaction)
    |> TransactionGate.BlockchainLocal.process_with_transaction()

    # TODO handle failure
  end
end
