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

defmodule EWallet.AddressTrackerTest do
  use EWallet.DBCase, async: false
  import EWalletDB.Factory
  alias EWallet.AddressTracker
  alias EWalletDB.Transaction
  alias Utils.Helpers.Crypto

  describe "start_link/1" do
    test "starts a new server" do
      _hot_wallet = insert(:blockchain_wallet, type: "hot")

      assert {:ok, pid} =
               AddressTracker.start_link(
                 name: :test_address_tracker,
                 attrs: %{blockchain: "dumb"}
               )

      assert is_pid(pid)
      assert GenServer.stop(pid) == :ok
    end
  end

  describe "init/1" do
    test "inits without addresses" do
      expected = %{
        addresses: %{},
        blk_number: 0,
        blk_retries: 0,
        blk_syncing_save_count: 0,
        blk_syncing_save_interval: 5,
        blockchain: "dumb",
        contract_addresses: [],
        adapter: nil,
        interval: 50,
        timer: nil
      }

      assert AddressTracker.init(%{blockchain: "dumb"}) ==
               {:ok, expected, {:continue, :start_polling}}
    end

    test "inits with addresses" do
      hot_wallet = insert(:blockchain_wallet, type: "hot", blockchain_identifier: "dumb")
      deposit_wallet = insert(:blockchain_deposit_wallet, blockchain_identifier: "dumb")

      token =
        insert(:token,
          blockchain_identifier: "dumb",
          blockchain_address: Crypto.fake_eth_address()
        )

      expected = %{
        addresses: %{
          hot_wallet.address => nil,
          deposit_wallet.address => deposit_wallet.wallet_address
        },
        blk_number: 0,
        blk_retries: 0,
        blk_syncing_save_count: 0,
        blk_syncing_save_interval: 5,
        blockchain: "dumb",
        adapter: :fake_adapter,
        contract_addresses: [
          token.blockchain_address
        ],
        interval: 50,
        timer: nil
      }

      assert AddressTracker.init(%{blockchain: "dumb", adapter: :fake_adapter}) ==
               {:ok, expected, {:continue, :start_polling}}
    end
  end

  # register_address
  # run

  describe "handle_call/3 with :register_address" do
  end

  describe "run/1 through polling" do
    test "" do
      transaction = insert(:blockchain_transaction)

      assert {:ok, pid} =
               AddressTracker.start_link(
                 name: :test_address_tracker_1,
                 attrs: %{
                   adapter: EthBlockchain.DumbAdapter,
                   blockchain: "dumb"
                 }
               )

      state = :sys.get_state(pid)
      IO.inspect(state)

      assert GenServer.stop(pid) == :ok

      # receive do
      #   {:DOWN, ^ref, _, _, _} ->
      #     transaction = Transaction.get(transaction.id)
      #     assert %{confirmations_count: 12, status: "confirmed"} = transaction
      # end

      refute Process.alive?(pid)
    end
  end
end
