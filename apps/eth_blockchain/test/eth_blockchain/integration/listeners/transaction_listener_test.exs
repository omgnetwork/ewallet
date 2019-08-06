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

defmodule EthBlockchain.Integration.TransactionListenerTest do
  use ExUnitFixtures
  use EthBlockchain.EthBlockchainIntegrationCase

  alias EthBlockchain.{DumbSubscriber, Transaction, TransactionListener}

  @moduletag :integration

  describe "run/1" do
    @tag fixtures: [:funded_hot_wallet, :alice]
    test "handles a valid transaction", %{funded_hot_wallet: hot_wallet, alice: alice} do
      {:ok, tx_hash} =
        Transaction.send(%{
          from: hot_wallet.address,
          to: alice.address,
          amount: 100
        })

      {:ok, pid} =
        TransactionListener.start_link(%{
          id: tx_hash,
          interval: 100,
          blockchain_adapter_pid: nil,
          node_adapter: nil
        })

      # Subscribe to the subscriber to get updates
      {:ok, subscriber_pid} =
        DumbSubscriber.start_link(%{subscriber: self(), retry_not_found_count: 100})

      :ok = GenServer.call(pid, {:subscribe, subscriber_pid})

      # The Dumb Subscriber will skip sending a :not_found event up to a 100 times
      # while waiting for a confirmation. As soon as the transaction is included
      # in a block (the receipt is not nil), it'll send an event containing its state.
      receive do
        state ->
          assert state[:confirmations_count] == 1
          receipt = state[:receipt]
          assert receipt.transaction_hash == tx_hash
          assert receipt.status == 1
      end

      assert GenServer.stop(subscriber_pid) == :ok
      assert GenServer.stop(pid) == :ok
    end
  end
end
