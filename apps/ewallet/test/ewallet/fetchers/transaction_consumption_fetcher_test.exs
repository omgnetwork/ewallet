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

defmodule EWallet.TransactionConsumptionFetcherTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias ActivityLogger.System

  alias EWallet.{
    TestEndpoint,
    TransactionConsumptionConsumerGate,
    TransactionConsumptionFetcher
  }

  alias EWalletDB.{Account, TransactionConsumption, User}

  setup do
    {:ok, pid} = TestEndpoint.start_link()

    on_exit(fn ->
      ref = Process.monitor(pid)
      assert_receive {:DOWN, ^ref, _, _, _}
    end)

    token = insert(:token)
    {:ok, receiver} = :user |> params_for() |> User.insert()
    {:ok, sender} = :user |> params_for() |> User.insert()
    account = Account.get_master_account()
    receiver_wallet = User.get_primary_wallet(receiver)
    sender_wallet = User.get_primary_wallet(sender)
    account_wallet = Account.get_primary_wallet(account)

    mint!(token)

    transaction_request =
      insert(
        :transaction_request,
        type: "receive",
        token_uuid: token.uuid,
        user_uuid: receiver.uuid,
        wallet: receiver_wallet,
        amount: 100_000 * token.subunit_to_unit
      )

    %{
      sender: sender,
      receiver: receiver,
      account: account,
      token: token,
      receiver_wallet: receiver_wallet,
      sender_wallet: sender_wallet,
      account_wallet: account_wallet,
      request: transaction_request
    }
  end

  describe "get/1" do
    test "returns the consumption when given valid ID", meta do
      initialize_wallet(meta.sender_wallet, 200_000, meta.token)

      {res, consumption} =
        TransactionConsumptionConsumerGate.consume(meta.sender, %{
          "formatted_transaction_request_id" => meta.request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "address" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "originator" => %System{}
        })

      assert res == :ok
      assert {:ok, consumption} = TransactionConsumptionFetcher.get(consumption.id)
      assert %TransactionConsumption{} = consumption
    end

    test "returns nil when given nil" do
      assert TransactionConsumptionFetcher.get(nil) ==
               {:error, :transaction_consumption_not_found}
    end

    test "returns nil when given invalid UUID" do
      assert TransactionConsumptionFetcher.get("123") ==
               {:error, :transaction_consumption_not_found}
    end
  end
end
