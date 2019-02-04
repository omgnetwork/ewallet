# Copyright 2018 OmiseGO Pte Ltd
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

defmodule EWallet.TransactionConsumptionConfirmerGateTest do
  # `async: false` as this test module spawns new processes that check out the sandbox
  use EWallet.DBCase, async: false
  import EWalletDB.Factory
  alias ActivityLogger.System
  alias Ecto.Adapters.SQL.Sandbox
  alias Ecto.UUID
  alias EWalletDB.Membership

  alias EWallet.{
    TestEndpoint,
    TransactionConsumptionConfirmerGate,
    TransactionConsumptionConsumerGate,
    TransactionRequestGate
  }

  alias EWalletDB.{Account, AccountUser, TransactionConsumption, TransactionRequest, User}

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

  describe "confirm/3 as user" do
    test "confirms the consumption for an end user if approved as admin user", meta do
      initialize_wallet(meta.sender_wallet, 200_000, meta.token)
      {:ok, _} = AccountUser.link(meta.account.uuid, meta.receiver.uuid, %System{})

      admin = insert(:admin)
      {:ok, _} = Membership.assign(admin, meta.account, "admin", %System{})

      transaction_request =
        insert(
          :transaction_request,
          type: "receive",
          require_confirmation: true,
          token_uuid: meta.token.uuid,
          account_uuid: meta.account.uuid,
          wallet: meta.receiver_wallet,
          amount: 100_000 * meta.token.subunit_to_unit
        )

      {res, consumption} =
        TransactionConsumptionConsumerGate.consume(%{
          "formatted_transaction_request_id" => transaction_request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "user_id" => meta.sender.id,
          "address" => meta.sender_wallet.address,
          "originator" => %System{}
        })

      assert res == :ok
      assert %TransactionConsumption{} = consumption
      assert consumption.status == "pending"
      assert consumption.approved_at == nil

      {:ok, consumption} =
        TransactionConsumptionConfirmerGate.confirm(
          consumption.id,
          true,
          %{
            admin_user: admin
          },
          %System{}
        )

      assert consumption.status == "confirmed"
      assert consumption.approved_at != nil
    end

    test "confirms the accoun tconsumption if approved as admin user with rights", meta do
      initialize_wallet(meta.sender_wallet, 200_000, meta.token)
      {:ok, account} = :account |> params_for() |> Account.insert()
      wallet = Account.get_primary_wallet(account)

      admin = insert(:admin)
      {:ok, _} = Membership.assign(admin, account, "admin", %System{})

      transaction_request =
        insert(
          :transaction_request,
          type: "receive",
          require_confirmation: true,
          token_uuid: meta.token.uuid,
          account_uuid: account.uuid,
          wallet: wallet,
          amount: 100_000 * meta.token.subunit_to_unit
        )

      {res, consumption} =
        TransactionConsumptionConsumerGate.consume(%{
          "formatted_transaction_request_id" => transaction_request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "user_id" => meta.sender.id,
          "address" => meta.sender_wallet.address,
          "originator" => %System{}
        })

      assert res == :ok
      assert %TransactionConsumption{} = consumption
      assert consumption.status == "pending"
      assert consumption.approved_at == nil

      {:ok, consumption} =
        TransactionConsumptionConfirmerGate.confirm(
          consumption.id,
          true,
          %{
            admin_user: admin
          },
          %System{}
        )

      assert consumption.status == "confirmed"
      assert consumption.approved_at != nil
    end

    test "fails to confirm the consumption if approved as admin user with no rights", meta do
      initialize_wallet(meta.sender_wallet, 200_000, meta.token)
      admin = insert(:admin)

      transaction_request =
        insert(
          :transaction_request,
          type: "receive",
          require_confirmation: true,
          token_uuid: meta.token.uuid,
          account_uuid: meta.account.uuid,
          wallet: meta.account_wallet,
          amount: 100_000 * meta.token.subunit_to_unit
        )

      {res, consumption} =
        TransactionConsumptionConsumerGate.consume(%{
          "formatted_transaction_request_id" => transaction_request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "user_id" => meta.sender.id,
          "address" => meta.sender_wallet.address,
          "originator" => %System{}
        })

      assert res == :ok
      assert %TransactionConsumption{} = consumption
      assert consumption.status == "pending"
      assert consumption.approved_at == nil

      {:error, :unauthorized} =
        TransactionConsumptionConfirmerGate.confirm(
          consumption.id,
          true,
          %{
            admin_user: admin
          },
          %System{}
        )
    end

    test "confirms a user's consumption if created and approved as admin user", meta do
      initialize_wallet(meta.sender_wallet, 200_000, meta.token)
      {:ok, _} = AccountUser.link(meta.account.uuid, meta.receiver.uuid, %System{})

      admin_1 = insert(:admin)
      {:ok, _} = Membership.assign(admin_1, meta.account, "admin", %System{})

      admin_2 = insert(:admin)
      {:ok, _} = Membership.assign(admin_2, meta.account, "admin", %System{})

      {:ok, request} =
        TransactionRequestGate.create(%{
          "type" => "receive",
          "token_id" => meta.token.id,
          "correlation_id" => "123",
          "amount" => 1_000,
          "account_id" => meta.account.id,
          "provider_user_id" => meta.receiver.provider_user_id,
          "address" => meta.receiver_wallet.address,
          "require_confirmation" => true,
          "creator" => %{admin_user: admin_1},
          "originator" => %System{}
        })

      {res, consumption} =
        TransactionConsumptionConsumerGate.consume(%{
          "formatted_transaction_request_id" => request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "user_id" => meta.sender.id,
          "address" => meta.sender_wallet.address,
          "originator" => %System{}
        })

      assert res == :ok
      assert %TransactionConsumption{} = consumption
      assert consumption.status == "pending"
      assert consumption.approved_at == nil

      {:ok, consumption} =
        TransactionConsumptionConfirmerGate.confirm(
          consumption.id,
          true,
          %{
            admin_user: admin_2
          },
          %System{}
        )

      assert consumption.status == "confirmed"
      assert consumption.approved_at != nil
    end

    test "fails to confirm the consumption if not owner", meta do
      initialize_wallet(meta.sender_wallet, 200_000, meta.token)
      account = insert(:account)

      transaction_request =
        insert(
          :transaction_request,
          type: "receive",
          require_confirmation: true,
          token_uuid: meta.token.uuid,
          user_uuid: meta.sender.uuid,
          amount: 100_000 * meta.token.subunit_to_unit
        )

      {res, consumption} =
        TransactionConsumptionConsumerGate.consume(%{
          "formatted_transaction_request_id" => transaction_request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "user_id" => meta.sender.id,
          "address" => meta.sender_wallet.address,
          "originator" => %System{}
        })

      assert res == :ok
      assert %TransactionConsumption{} = consumption
      assert consumption.status == "pending"
      assert consumption.approved_at == nil

      res =
        TransactionConsumptionConfirmerGate.confirm(
          consumption.id,
          true,
          %{
            account: account
          },
          %System{}
        )

      assert res == {:error, :unauthorized}
    end

    test "fails to confirm the consumption if expired", meta do
      initialize_wallet(meta.sender_wallet, 200_000, meta.token)
      {:ok, _} = AccountUser.link(meta.account.uuid, meta.receiver.uuid, %System{})

      admin = insert(:admin)
      {:ok, _} = Membership.assign(admin, meta.account, "admin", %System{})

      transaction_request =
        insert(
          :transaction_request,
          type: "receive",
          require_confirmation: true,
          token_uuid: meta.token.uuid,
          account_uuid: meta.account.uuid,
          wallet: meta.receiver_wallet,
          amount: 100_000 * meta.token.subunit_to_unit
        )

      {res, consumption} =
        TransactionConsumptionConsumerGate.consume(%{
          "formatted_transaction_request_id" => transaction_request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "user_id" => meta.sender.id,
          "address" => meta.sender_wallet.address,
          "originator" => %System{}
        })

      assert res == :ok
      assert %TransactionConsumption{} = consumption
      assert consumption.status == "pending"
      assert consumption.approved_at == nil

      {:ok, transaction_request} = TransactionRequest.expire(transaction_request, %System{})
      assert transaction_request.expired_at != nil

      res =
        TransactionConsumptionConfirmerGate.confirm(
          consumption.id,
          true,
          %{
            admin_user: admin
          },
          %System{}
        )

      assert res == {:error, :expired_transaction_request}
    end

    test "rejects the consumption if not confirmed as admin user with rights", meta do
      initialize_wallet(meta.sender_wallet, 200_000, meta.token)
      {:ok, _} = AccountUser.link(meta.account.uuid, meta.receiver.uuid, %System{})
      admin = insert(:admin)
      {:ok, _} = Membership.assign(admin, meta.account, "admin", %System{})

      transaction_request =
        insert(
          :transaction_request,
          type: "receive",
          require_confirmation: true,
          token_uuid: meta.token.uuid,
          account_uuid: meta.account.uuid,
          wallet: meta.receiver_wallet,
          amount: 100_000 * meta.token.subunit_to_unit
        )

      {res, consumption} =
        TransactionConsumptionConsumerGate.consume(%{
          "formatted_transaction_request_id" => transaction_request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "user_id" => meta.sender.id,
          "address" => meta.sender_wallet.address,
          "originator" => %System{}
        })

      assert res == :ok
      assert %TransactionConsumption{} = consumption
      assert consumption.status == "pending"
      assert consumption.approved_at == nil

      {:ok, consumption} =
        TransactionConsumptionConfirmerGate.confirm(
          consumption.id,
          false,
          %{
            admin_user: admin
          },
          %System{}
        )

      assert consumption.status == "rejected"
      assert consumption.approved_at == nil
    end

    test "allows only one confirmation with two confirms at the same time", meta do
      initialize_wallet(meta.sender_wallet, 1_000_000, meta.token)
      {:ok, _} = AccountUser.link(meta.account.uuid, meta.receiver.uuid, %System{})
      admin = insert(:admin)
      {:ok, _} = Membership.assign(admin, meta.account, "admin", %System{})

      request =
        insert(
          :transaction_request,
          type: "receive",
          require_confirmation: true,
          token_uuid: meta.token.uuid,
          account_uuid: meta.account.uuid,
          wallet: meta.receiver_wallet,
          amount: 100_000 * meta.token.subunit_to_unit,
          max_consumptions: 1
        )

      params = fn ->
        %{
          "formatted_transaction_request_id" => request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => UUID.generate(),
          "token_id" => nil,
          "user_id" => meta.sender.id,
          "address" => meta.sender_wallet.address,
          "originator" => %System{}
        }
      end

      max = 10
      range = Enum.into(1..max, [])

      consumptions =
        Enum.map(range, fn _i ->
          {:ok, consumption} = TransactionConsumptionConsumerGate.consume(params.())
          consumption
        end)

      Enum.each(consumptions, fn c ->
        assert c.status == "pending"
      end)

      pid = self()

      consumptions
      |> Enum.with_index()
      |> Enum.each(fn {c, i} ->
        {:ok, _new_pid} =
          Task.start_link(fn ->
            Sandbox.allow(EWalletDB.Repo, pid, self())
            Sandbox.allow(LocalLedgerDB.Repo, pid, self())

            {res, response} =
              TransactionConsumptionConfirmerGate.confirm(
                c.id,
                true,
                %{
                  admin_user: admin
                },
                %System{}
              )

            send(pid, {String.to_atom("updated_#{i + 1}"), res, response})
          end)
      end)

      Enum.each(range, fn i ->
        update = String.to_atom("updated_#{i}")
        assert_receive {^update, _res, _response}, 5000
      end)

      consumptions = TransactionConsumption |> EWalletDB.Repo.all()
      assert length(consumptions) == max
      assert Enum.count(consumptions, fn c -> c.status == "confirmed" end) == 1
      assert Enum.count(consumptions, fn c -> c.status == "pending" end) == max - 1
    end
  end

  describe "confirm/3 with User" do
    test "confirms the consumption if approved as user", meta do
      initialize_wallet(meta.sender_wallet, 200_000, meta.token)

      transaction_request =
        insert(
          :transaction_request,
          type: "receive",
          require_confirmation: true,
          token_uuid: meta.token.uuid,
          user_uuid: meta.receiver.uuid,
          wallet: meta.receiver_wallet,
          amount: 100_000 * meta.token.subunit_to_unit
        )

      {res, consumption} =
        TransactionConsumptionConsumerGate.consume(%{
          "formatted_transaction_request_id" => transaction_request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "user_id" => meta.sender.id,
          "address" => meta.sender_wallet.address,
          "originator" => %System{}
        })

      assert res == :ok
      assert %TransactionConsumption{} = consumption
      assert consumption.status == "pending"
      assert consumption.approved_at == nil

      {:ok, consumption} =
        TransactionConsumptionConfirmerGate.confirm(
          consumption.id,
          true,
          %{
            end_user: meta.receiver
          },
          %System{}
        )

      assert consumption.status == "confirmed"
      assert consumption.approved_at != nil
    end

    test "confirms a user's consumption if created and approved as user", meta do
      initialize_wallet(meta.sender_wallet, 200_000, meta.token)

      {res, request} =
        TransactionRequestGate.create(%{
          "type" => "receive",
          "token_id" => meta.token.id,
          "correlation_id" => "123",
          "amount" => 1_000,
          "account_id" => meta.account.id,
          "provider_user_id" => meta.receiver.provider_user_id,
          "address" => meta.receiver_wallet.address,
          "require_confirmation" => true,
          "creator" => %{end_user: meta.receiver},
          "originator" => %System{}
        })

      assert res == :ok

      {res, consumption} =
        TransactionConsumptionConsumerGate.consume(%{
          "formatted_transaction_request_id" => request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "user_id" => meta.sender.id,
          "address" => meta.sender_wallet.address,
          "originator" => %System{}
        })

      assert res == :ok
      assert %TransactionConsumption{} = consumption
      assert consumption.status == "pending"
      assert consumption.approved_at == nil

      {:ok, consumption} =
        TransactionConsumptionConfirmerGate.confirm(
          consumption.id,
          true,
          %{
            end_user: meta.receiver
          },
          %System{}
        )

      assert consumption.status == "confirmed"
      assert consumption.approved_at != nil
    end

    test "fails to confirm the consumption if not owner", meta do
      initialize_wallet(meta.sender_wallet, 200_000, meta.token)

      transaction_request =
        insert(
          :transaction_request,
          type: "receive",
          require_confirmation: true,
          token_uuid: meta.token.uuid,
          user_uuid: meta.receiver.uuid,
          amount: 100_000 * meta.token.subunit_to_unit
        )

      {res, consumption} =
        TransactionConsumptionConsumerGate.consume(%{
          "formatted_transaction_request_id" => transaction_request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "user_id" => meta.sender.id,
          "address" => meta.sender_wallet.address,
          "originator" => %System{}
        })

      assert res == :ok
      assert %TransactionConsumption{} = consumption
      assert consumption.status == "pending"
      assert consumption.approved_at == nil

      res =
        TransactionConsumptionConfirmerGate.confirm(
          consumption.id,
          true,
          %{
            end_user: meta.sender
          },
          %System{}
        )

      assert res == {:error, :unauthorized}
    end

    test "fails to confirm the consumption if expired", meta do
      initialize_wallet(meta.sender_wallet, 200_000, meta.token)

      transaction_request =
        insert(
          :transaction_request,
          type: "receive",
          require_confirmation: true,
          token_uuid: meta.token.uuid,
          user_uuid: meta.receiver.uuid,
          wallet: meta.receiver_wallet,
          amount: 100_000 * meta.token.subunit_to_unit
        )

      {res, consumption} =
        TransactionConsumptionConsumerGate.consume(%{
          "formatted_transaction_request_id" => transaction_request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "user_id" => meta.sender.id,
          "address" => meta.sender_wallet.address,
          "originator" => %System{}
        })

      assert res == :ok
      assert %TransactionConsumption{} = consumption
      assert consumption.status == "pending"
      assert consumption.approved_at == nil

      {:ok, transaction_request} = TransactionRequest.expire(transaction_request, %System{})
      assert transaction_request.expired_at != nil

      res =
        TransactionConsumptionConfirmerGate.confirm(
          consumption.id,
          true,
          %{
            end_user: meta.receiver
          },
          %System{}
        )

      assert res == {:error, :expired_transaction_request}
    end
  end
end
