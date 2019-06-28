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

defmodule EWallet.BlockchainTransactionGateTest do
  use EWallet.DBCase, async: false
  import EWalletDB.Factory
  alias EWallet.{BlockchainTransactionGate, TransactionRegistry}
  alias EWalletDB.BlockchainWallet
  alias ActivityLogger.System
  alias Utils.Helpers.Crypto

  describe "create/2" do
    test "submits a transaction to the blockchain subapp (hot wallet to blockchain address)",
         meta do
      # TODO switch to using the seeded Ethereum
      token = insert(:token, blockchain_address: "0x0000000000000000000000000000000000000000")
      hot_wallet = BlockchainWallet.get_primary_hot_wallet()

      attrs = %{
        "from_address" => hot_wallet.address,
        "to_address" => Crypto.fake_eth_address(),
        "token_id" => token.id,
        "amount" => 1,
        "originator" => %System{}
      }

      {:ok, transaction} = BlockchainTransactionGate.create(attrs, [true, true])

      assert transaction.status == "submitted"
      assert transaction.type == "external"
      assert transaction.blockchain_identifier == "ethereum"
      assert transaction.confirmations_count == nil

      {:ok, res} = TransactionRegistry.lookup(transaction.uuid)
      assert %{listener: EWallet.TransactionListener, pid: pid} = res

      {:ok, res} = meta[:adapter].lookup_listener(transaction.blockchain_tx_hash)
      assert %{listener: _, pid: blockchain_listener_pid} = res

      ref = Process.monitor(pid)

      receive do
        {:DOWN, ^ref, _, _, _} ->
          IO.puts("Process ewallet listener #{inspect(pid)} is down")
      end

      ref = Process.monitor(blockchain_listener_pid)

      receive do
        {:DOWN, ^ref, _, _, _} ->
          IO.puts("Process blockchain listener #{inspect(pid)} is down")
      end
    end
  end
end
