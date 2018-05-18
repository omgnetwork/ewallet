defmodule EWallet.TransactionConsumptionFetcherTest do
  use EWallet.LocalLedgerCase, async: true
  alias Ecto.Adapters.SQL.Sandbox

  alias EWallet.{
    TestEndpoint,
    TransactionConsumptionConsumerGate,
    TransactionConsumptionFetcher
  }

  alias EWalletDB.{User, TransactionConsumption}

  setup do
    {:ok, _} = TestEndpoint.start_link()

    minted_token = insert(:minted_token)
    {:ok, receiver} = :user |> params_for() |> User.insert()
    {:ok, sender} = :user |> params_for() |> User.insert()
    account = Account.get_master_account()
    receiver_balance = User.get_primary_balance(receiver)
    sender_balance = User.get_primary_balance(sender)
    account_balance = Account.get_primary_balance(account)

    mint!(minted_token)

    transaction_request =
      insert(
        :transaction_request,
        type: "receive",
        minted_token_uuid: minted_token.uuid,
        user_uuid: receiver.uuid,
        balance: receiver_balance,
        amount: 100_000 * minted_token.subunit_to_unit
      )

    %{
      sender: sender,
      receiver: receiver,
      account: account,
      minted_token: minted_token,
      receiver_balance: receiver_balance,
      sender_balance: sender_balance,
      account_balance: account_balance,
      request: transaction_request
    }
  end

  describe "get/1" do
    test "returns the consumption when given valid ID", meta do
      initialize_balance(meta.sender_balance, 200_000, meta.minted_token)

      {res, consumption} =
        TransactionConsumptionConsumerGate.consume(meta.sender, %{
          "transaction_request_id" => meta.request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "address" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil
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
