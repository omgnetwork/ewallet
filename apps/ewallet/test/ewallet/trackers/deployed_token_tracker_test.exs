# Copyright 2018-2019 OMG Network Pte Ltd
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

defmodule EWallet.DeployedTokenTrackerTest do
  use EWallet.DBCase, async: false
  import EWalletDB.Factory

  alias EWallet.{BlockchainHelper, DeployedTokenTracker}

  alias EWalletDB.{
    Token,
    BlockchainState,
    BlockchainTransactionState
  }

  describe "start_all_pending/0" do
    test "restarts trackers for all pending token" do
      identifier = BlockchainHelper.rootchain_identifier()

      blockchain_transaction_1 =
        insert(:blockchain_transaction_rootchain, status: BlockchainTransactionState.submitted())

      blockchain_transaction_2 =
        insert(:blockchain_transaction_rootchain,
          status: BlockchainTransactionState.pending_confirmations()
        )

      blockchain_transaction_3 =
        insert(:blockchain_transaction_rootchain, status: BlockchainTransactionState.confirmed())

      token_1 =
        insert(:internal_blockchain_token,
          blockchain_status: Token.Blockchain.status_pending(),
          blockchain_transaction_uuid: blockchain_transaction_1.uuid
        )

      token_2 =
        insert(:internal_blockchain_token,
          blockchain_status: Token.Blockchain.status_pending(),
          blockchain_transaction_uuid: blockchain_transaction_2.uuid
        )

      _ =
        insert(:internal_blockchain_token,
          blockchain_status: Token.Blockchain.status_confirmed(),
          blockchain_transaction_uuid: blockchain_transaction_3.uuid
        )

      # Fast forward the blockchain manually to have the transactions confirmed.
      BlockchainState.update(identifier, 20)

      started_trackers = DeployedTokenTracker.start_all_pending()

      assert length(started_trackers) == 2

      Enum.each(started_trackers, fn {res, pid} ->
        assert res == :ok
        assert is_pid(pid)
        ref = Process.monitor(pid)

        receive do
          {:DOWN, ^ref, _, ^pid, _} -> :ok
        end

        refute Process.alive?(pid)

        assert Token.get_by(uuid: token_1.uuid).blockchain_status ==
                 Token.Blockchain.status_confirmed()

        assert Token.get_by(uuid: token_2.uuid).blockchain_status ==
                 Token.Blockchain.status_confirmed()
      end)
    end
  end

  describe "start/1" do
    test "starts a new DeployedTokenTracker" do
      blockchain_transaction = insert(:blockchain_transaction_rootchain)

      token =
        insert(:internal_blockchain_token,
          blockchain_transaction_uuid: blockchain_transaction.uuid
        )

      token = Token.get(token.id, preload: :blockchain_transaction)

      assert {:ok, pid} = DeployedTokenTracker.start(token)

      assert is_pid(pid)
      assert GenServer.stop(pid) == :ok
    end
  end

  describe "on_confirmed/1" do
    test "process the confirmed token" do
      blochain_transaction =
        insert(:blockchain_transaction_rootchain, %{status: Token.Blockchain.status_confirmed()})

      token =
        insert(:internal_blockchain_token, %{
          blockchain_status: Token.Blockchain.status_pending(),
          blockchain_transaction_uuid: blochain_transaction.uuid
        })

      token = Token.get(token.id, preload: :blockchain_transaction)

      assert token.blockchain_status == Token.Blockchain.status_pending()

      assert {:ok, updated_token} = DeployedTokenTracker.on_confirmed(blochain_transaction)
      assert updated_token.blockchain_status == Token.Blockchain.status_confirmed()
    end
  end
end
