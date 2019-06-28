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

defmodule EWallet.TransactionListener do
  use GenServer, restart: :temporary

  alias EWallet.BlockchainTransactionState
  alias ActivityLogger.System

  def start_link(transaction) do
    IO.inspect("Starting transaction listener for #{transaction.blockchain_tx_hash}")
    GenServer.start_link(__MODULE__, transaction)
  end

  def init(transaction) do
    # register as listener
    # handle updates
    adapter = Application.get_env(:ewallet, :blockchain_adapter)
    :ok = adapter.subscribe(:transaction, transaction.blockchain_tx_hash, self())
    {:ok, transaction}
  end

  def handle_cast({:confirmations_count, tx_hash, confirmations_count}, transaction) do
    # case tx_hash == transaction.tx_hash -> LOL
    # Check confirmation count from config
    adapter = Application.get_env(:ewallet, :blockchain_adapter)

    # TODO: get confirmations from settings
    case confirmations_count > 6 do
      true ->
        # Reach full confirmation
        {:ok, transaction} =
          BlockchainTransactionState.transition_to(
            :confirmed,
            transaction,
            confirmations_count,
            %System{}
          )

        :ok = adapter.unsubscribe(:transaction, transaction.blockchain_tx_hash, self())

        # Kill thyself
        {:stop, :normal, transaction}

      false ->
        case BlockchainTransactionState.transition_to(
               :pending_confirmations,
               transaction,
               confirmations_count,
               %System{}
             ) do
          {:ok, transaction} ->
            {:noreply, transaction}

          a ->
            # TODO
            IO.inspect(a)
            {:noreply, transaction}
        end
    end
  end
end
