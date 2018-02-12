defmodule EWalletAPI.V1.TransactionRequestConsumptionControllerTest do
  use EWalletAPI.ConnCase, async: true
  alias EWalletDB.{Repo, TransactionRequestConsumption, User, Transfer}

  describe "consume/2" do
    # No idempotency?
    # with transaction request created through API
    # with address / without address in request
    # with amount / without amount in request
    test "" do
      minted_token        = insert(:minted_token)
      {:ok, alice}        = User.insert(%{
        username: "alice",
        provider_user_id: "alice",
        metadata: %{}
      })   # receiver
      bob                 = get_test_user() # sender
      alice_balance       = User.get_primary_balance(alice)
      bob_balance         = User.get_primary_balance(bob)

      transaction_request = insert(:transaction_request,
        type: "receive",
        minted_token_id: minted_token.id,
        user_id: alice.id,
        balance: alice_balance,
        amount: 100_000 * minted_token.subunit_to_unit
      )

      set_initial_balance(%{
        address: bob_balance.address,
        minted_token: minted_token,
        amount: 150_000
      })

      response = client_request_with_idempotency("/me.consume_transaction_request", "123", %{
        transaction_request_id: transaction_request.id,
        correlation_id: nil,
        amount: nil,
        address: nil,
        metadata: nil
      })

      inserted_consumption = TransactionRequestConsumption |> Repo.all() |> Enum.at(0)
      inserted_transfer    = Repo.get(Transfer, inserted_consumption.transfer_id)

      assert response == %{
        "success" => true,
        "version" => "1",
        "data" => %{
          "address" => bob_balance.address,
          "amount" => 100_000 * minted_token.subunit_to_unit,
          "correlation_id" => nil,
          "id" => inserted_consumption.id,
          "idempotency_token" => "123",
          "object" => "transaction_request_consumption",
          "status" => "confirmed",
          "token_id" => minted_token.friendly_id,
          "transaction_request_id" => transaction_request.id,
          "transfer_id" => inserted_transfer.id,
          "user_id" => bob.id
        }
      }

      assert inserted_transfer.amount == 100_000 * minted_token.subunit_to_unit
      assert inserted_transfer.to == alice_balance.address
      assert inserted_transfer.from == bob_balance.address
      assert %{} = inserted_transfer.ledger_response
    end
  end
end
