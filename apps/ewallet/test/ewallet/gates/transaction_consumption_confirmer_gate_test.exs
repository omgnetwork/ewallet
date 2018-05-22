defmodule EWallet.TransactionConsumptionConfirmerGateTest do
  use EWallet.LocalLedgerCase, async: true
  alias Ecto.Adapters.SQL.Sandbox
  alias Ecto.UUID

  alias EWallet.{
    TestEndpoint,
    TransactionRequestGate,
    TransactionConsumptionConfirmerGate,
    TransactionConsumptionConsumerGate
  }

  alias EWalletDB.{User, TransactionConsumption, TransactionRequest}

  setup do
    {:ok, _} = TestEndpoint.start_link()

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

  describe "confirm/3 with Account" do
    test "confirms the consumption if approved as account", meta do
      initialize_wallet(meta.sender_wallet, 200_000, meta.token)

      transaction_request =
        insert(
          :transaction_request,
          type: "receive",
          require_confirmation: true,
          token_uuid: meta.token.uuid,
          account_uuid: meta.account.uuid,
          amount: 100_000 * meta.token.subunit_to_unit
        )

      {res, consumption} =
        TransactionConsumptionConsumerGate.consume(%{
          "transaction_request_id" => transaction_request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "user_id" => meta.sender.id,
          "address" => meta.sender_wallet.address
        })

      assert res == :ok
      assert %TransactionConsumption{} = consumption
      assert consumption.status == "pending"
      assert consumption.approved_at == nil

      {:ok, consumption} =
        TransactionConsumptionConfirmerGate.confirm(consumption.id, true, meta.account)

      assert consumption.status == "confirmed"
      assert consumption.approved_at != nil
    end

    test "confirms a user's consumption if created and approved as account", meta do
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
          "require_confirmation" => true
        })

      assert res == :ok

      {res, consumption} =
        TransactionConsumptionConsumerGate.consume(%{
          "transaction_request_id" => request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "user_id" => meta.sender.id,
          "address" => meta.sender_wallet.address
        })

      assert res == :ok
      assert %TransactionConsumption{} = consumption
      assert consumption.status == "pending"
      assert consumption.approved_at == nil

      {:ok, consumption} =
        TransactionConsumptionConfirmerGate.confirm(consumption.id, true, meta.account)

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
          user_uuid: meta.sender.uuid,
          amount: 100_000 * meta.token.subunit_to_unit
        )

      {res, consumption} =
        TransactionConsumptionConsumerGate.consume(%{
          "transaction_request_id" => transaction_request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "user_id" => meta.sender.id,
          "address" => meta.sender_wallet.address
        })

      assert res == :ok
      assert %TransactionConsumption{} = consumption
      assert consumption.status == "pending"
      assert consumption.approved_at == nil

      res = TransactionConsumptionConfirmerGate.confirm(consumption.id, true, meta.account)
      assert res == {:error, :not_transaction_request_owner}
    end

    test "fails to confirm the consumption if expired", meta do
      initialize_wallet(meta.sender_wallet, 200_000, meta.token)

      transaction_request =
        insert(
          :transaction_request,
          type: "receive",
          require_confirmation: true,
          token_uuid: meta.token.uuid,
          account_uuid: meta.account.uuid,
          amount: 100_000 * meta.token.subunit_to_unit
        )

      {res, consumption} =
        TransactionConsumptionConsumerGate.consume(%{
          "transaction_request_id" => transaction_request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "user_id" => meta.sender.id,
          "address" => meta.sender_wallet.address
        })

      assert res == :ok
      assert %TransactionConsumption{} = consumption
      assert consumption.status == "pending"
      assert consumption.approved_at == nil

      {:ok, transaction_request} = TransactionRequest.expire(transaction_request)
      assert transaction_request.expired_at != nil

      res = TransactionConsumptionConfirmerGate.confirm(consumption.id, true, meta.account)
      assert res == {:error, :expired_transaction_request}
    end

    test "rejects the consumption if not approved as account", meta do
      initialize_wallet(meta.sender_wallet, 200_000, meta.token)

      transaction_request =
        insert(
          :transaction_request,
          type: "receive",
          require_confirmation: true,
          token_uuid: meta.token.uuid,
          account_uuid: meta.account.uuid,
          amount: 100_000 * meta.token.subunit_to_unit
        )

      {res, consumption} =
        TransactionConsumptionConsumerGate.consume(%{
          "transaction_request_id" => transaction_request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "user_id" => meta.sender.id,
          "address" => meta.sender_wallet.address
        })

      assert res == :ok
      assert %TransactionConsumption{} = consumption
      assert consumption.status == "pending"
      assert consumption.approved_at == nil

      {:ok, consumption} =
        TransactionConsumptionConfirmerGate.confirm(consumption.id, false, meta.account)

      assert consumption.status == "rejected"
      assert consumption.approved_at == nil
    end

    test "allows only one confirmation with two confirms at the same time", meta do
      initialize_wallet(meta.sender_wallet, 1_000_000, meta.token)

      request =
        insert(
          :transaction_request,
          type: "receive",
          require_confirmation: true,
          token_uuid: meta.token.uuid,
          account_uuid: meta.account.uuid,
          amount: 100_000 * meta.token.subunit_to_unit,
          max_consumptions: 1
        )

      params = fn ->
        %{
          "transaction_request_id" => request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => UUID.generate(),
          "token_id" => nil,
          "user_id" => meta.sender.id,
          "address" => meta.sender_wallet.address
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
              TransactionConsumptionConfirmerGate.confirm(c.id, true, meta.account)

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
          amount: 100_000 * meta.token.subunit_to_unit
        )

      {res, consumption} =
        TransactionConsumptionConsumerGate.consume(%{
          "transaction_request_id" => transaction_request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "user_id" => meta.sender.id,
          "address" => meta.sender_wallet.address
        })

      assert res == :ok
      assert %TransactionConsumption{} = consumption
      assert consumption.status == "pending"
      assert consumption.approved_at == nil

      {:ok, consumption} =
        TransactionConsumptionConfirmerGate.confirm(consumption.id, true, meta.receiver)

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
          "require_confirmation" => true
        })

      assert res == :ok

      {res, consumption} =
        TransactionConsumptionConsumerGate.consume(%{
          "transaction_request_id" => request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "user_id" => meta.sender.id,
          "address" => meta.sender_wallet.address
        })

      assert res == :ok
      assert %TransactionConsumption{} = consumption
      assert consumption.status == "pending"
      assert consumption.approved_at == nil

      {:ok, consumption} =
        TransactionConsumptionConfirmerGate.confirm(consumption.id, true, meta.receiver)

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
          "transaction_request_id" => transaction_request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "user_id" => meta.sender.id,
          "address" => meta.sender_wallet.address
        })

      assert res == :ok
      assert %TransactionConsumption{} = consumption
      assert consumption.status == "pending"
      assert consumption.approved_at == nil

      res = TransactionConsumptionConfirmerGate.confirm(consumption.id, true, meta.sender)
      assert res == {:error, :not_transaction_request_owner}
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
          amount: 100_000 * meta.token.subunit_to_unit
        )

      {res, consumption} =
        TransactionConsumptionConsumerGate.consume(%{
          "transaction_request_id" => transaction_request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "user_id" => meta.sender.id,
          "address" => meta.sender_wallet.address
        })

      assert res == :ok
      assert %TransactionConsumption{} = consumption
      assert consumption.status == "pending"
      assert consumption.approved_at == nil

      {:ok, transaction_request} = TransactionRequest.expire(transaction_request)
      assert transaction_request.expired_at != nil

      res = TransactionConsumptionConfirmerGate.confirm(consumption.id, true, meta.receiver)
      assert res == {:error, :expired_transaction_request}
    end

    test "rejects the consumption if not approved as account", meta do
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
          "transaction_request_id" => transaction_request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "user_id" => meta.sender.id,
          "address" => meta.sender_wallet.address
        })

      assert res == :ok
      assert %TransactionConsumption{} = consumption
      assert consumption.status == "pending"
      assert consumption.approved_at == nil

      {:ok, consumption} =
        TransactionConsumptionConfirmerGate.confirm(consumption.id, false, meta.receiver)

      assert consumption.status == "rejected"
      assert consumption.approved_at == nil
    end
  end
end
