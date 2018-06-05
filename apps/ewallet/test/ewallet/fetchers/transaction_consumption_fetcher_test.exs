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
