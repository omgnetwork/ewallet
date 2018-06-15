defmodule EWalletAPI.V1.TransferControllerTest do
  use EWalletAPI.ConnCase, async: true
  alias EWalletDB.{User, Transfer}
  alias Ecto.UUID
  alias EWallet.Web.Date
  alias EWallet.BalanceFetcher

  describe "/me.transfer" do
    test "returns idempotency error if header is not specified" do
      wallet1 = User.get_primary_wallet(get_test_user())
      wallet2 = insert(:wallet)
      token = insert(:token)

      request_data = %{
        from_address: wallet1.address,
        to_address: wallet2.address,
        token_id: token.id,
        amount: 1_000 * token.subunit_to_unit,
        metadata: %{}
      }

      response = client_request("/me.transfer", request_data)

      assert response == %{
               "success" => false,
               "version" => "1",
               "data" => %{
                 "code" => "client:invalid_parameter",
                 "description" => "Invalid parameter provided",
                 "messages" => nil,
                 "object" => "error"
               }
             }
    end

    test "updates the wallets and returns the transaction" do
      wallet1 = User.get_primary_wallet(get_test_user())
      wallet2 = insert(:wallet)
      token = insert(:token)

      set_initial_balance(%{
        address: wallet1.address,
        token: token,
        amount: 200_000
      })

      response =
        client_request("/me.transfer", %{
          idempotency_token: UUID.generate(),
          from_address: wallet1.address,
          to_address: wallet2.address,
          token_id: token.id,
          amount: 100 * token.subunit_to_unit,
          metadata: %{something: "interesting"},
          encrypted_metadata: %{something: "secret"}
        })

      {:ok, b1} = BalanceFetcher.get(token.id, wallet1)
      assert List.first(b1.balances).amount == (200_000 - 100) * token.subunit_to_unit
      {:ok, b2} = BalanceFetcher.get(token.id, wallet2)
      assert List.first(b2.balances).amount == 100 * token.subunit_to_unit

      transfer = get_last_inserted(Transfer)

      assert response == %{
               "success" => true,
               "version" => "1",
               "data" => %{
                 "object" => "transaction",
                 "id" => transfer.id,
                 "idempotency_token" => transfer.idempotency_token,
                 "from" => %{
                   "object" => "transaction_source",
                   "address" => transfer.from,
                   "amount" => transfer.amount,
                   "token_id" => token.id,
                   "token" => %{
                     "name" => token.name,
                     "object" => "token",
                     "subunit_to_unit" => token.subunit_to_unit,
                     "id" => token.id,
                     "symbol" => token.symbol,
                     "metadata" => %{},
                     "encrypted_metadata" => %{},
                     "created_at" => Date.to_iso8601(token.inserted_at),
                     "updated_at" => Date.to_iso8601(token.updated_at)
                   }
                 },
                 "to" => %{
                   "object" => "transaction_source",
                   "address" => transfer.to,
                   "amount" => transfer.amount,
                   "token_id" => token.id,
                   "token" => %{
                     "name" => token.name,
                     "object" => "token",
                     "subunit_to_unit" => 100,
                     "id" => token.id,
                     "symbol" => token.symbol,
                     "metadata" => %{},
                     "encrypted_metadata" => %{},
                     "created_at" => Date.to_iso8601(token.inserted_at),
                     "updated_at" => Date.to_iso8601(token.updated_at)
                   }
                 },
                 "exchange" => %{
                   "object" => "exchange",
                   "rate" => 1
                 },
                 "metadata" => transfer.metadata || %{},
                 "encrypted_metadata" => transfer.encrypted_metadata || %{},
                 "status" => transfer.status,
                 "created_at" => Date.to_iso8601(transfer.inserted_at),
                 "updated_at" => Date.to_iso8601(transfer.updated_at)
               }
             }
    end

    test "returns a 'same_address' error when the addresses are the same" do
      wallet = User.get_primary_wallet(get_test_user())
      token = insert(:token)

      response =
        client_request("/me.transfer", %{
          idempotency_token: UUID.generate(),
          from_address: wallet.address,
          to_address: wallet.address,
          token_id: token.id,
          amount: 100_000 * token.subunit_to_unit
        })

      assert response == %{
               "success" => false,
               "version" => "1",
               "data" => %{
                 "code" => "transaction:same_address",
                 "description" =>
                   "Found identical addresses in senders and receivers: #{wallet.address}.",
                 "messages" => nil,
                 "object" => "error"
               }
             }
    end

    test "returns insufficient_funds when the user is too poor :~(" do
      wallet1 = User.get_primary_wallet(get_test_user())
      wallet2 = insert(:wallet)
      token = insert(:token)

      response =
        client_request("/me.transfer", %{
          idempotency_token: UUID.generate(),
          from_address: wallet1.address,
          to_address: wallet2.address,
          token_id: token.id,
          amount: 100_000 * token.subunit_to_unit
        })

      assert response == %{
               "success" => false,
               "version" => "1",
               "data" => %{
                 "code" => "transaction:insufficient_funds",
                 "description" =>
                   "The specified wallet (#{wallet1.address}) does not " <>
                     "contain enough funds. Available: 0.0 #{token.id} - " <>
                     "Attempted debit: 100000.0 #{token.id}",
                 "messages" => nil,
                 "object" => "error"
               }
             }
    end

    test "returns from_address_not_found when no wallet found for the 'from_address'" do
      wallet = insert(:wallet)
      token = insert(:token)

      response =
        client_request("/me.transfer", %{
          idempotency_token: UUID.generate(),
          from_address: "00000000-0000-0000-0000-000000000000",
          to_address: wallet.address,
          token_id: token.id,
          amount: 100_000
        })

      assert response == %{
               "success" => false,
               "version" => "1",
               "data" => %{
                 "code" => "user:from_address_not_found",
                 "description" => "No wallet found for the provided from_address.",
                 "messages" => nil,
                 "object" => "error"
               }
             }
    end

    test "returns a from_address_mismatch error if 'from_address' does not belong to the user" do
      wallet1 = insert(:wallet)
      wallet2 = insert(:wallet)
      token = insert(:token)

      response =
        client_request("/me.transfer", %{
          idempotency_token: UUID.generate(),
          from_address: wallet1.address,
          to_address: wallet2.address,
          token_id: token.id,
          amount: 100_000
        })

      assert response == %{
               "success" => false,
               "version" => "1",
               "data" => %{
                 "code" => "user:from_address_mismatch",
                 "description" =>
                   "The provided wallet address does not belong to the current user.",
                 "messages" => nil,
                 "object" => "error"
               }
             }
    end

    test "returns to_address_not_found when the to wallet is not found" do
      wallet = User.get_primary_wallet(get_test_user())
      token = insert(:token)

      response =
        client_request("/me.transfer", %{
          idempotency_token: UUID.generate(),
          from_address: wallet.address,
          to_address: "00000000-0000-0000-0000-000000000000",
          token_id: token.id,
          amount: 100_000
        })

      assert response == %{
               "success" => false,
               "version" => "1",
               "data" => %{
                 "code" => "user:to_address_not_found",
                 "description" => "No wallet found for the provided to_address.",
                 "messages" => nil,
                 "object" => "error"
               }
             }
    end

    test "returns token_not_found when the token is not found" do
      wallet1 = User.get_primary_wallet(get_test_user())
      wallet2 = insert(:wallet)

      response =
        client_request("/me.transfer", %{
          idempotency_token: UUID.generate(),
          from_address: wallet1.address,
          to_address: wallet2.address,
          token_id: "BTC:456",
          amount: 100_000
        })

      assert response == %{
               "success" => false,
               "version" => "1",
               "data" => %{
                 "code" => "token:token_not_found",
                 "description" => "There is no token matching the provided token_id.",
                 "messages" => nil,
                 "object" => "error"
               }
             }
    end

    test "takes primary wallet if 'from_address' is not specified" do
      wallet1 = User.get_primary_wallet(get_test_user())
      wallet2 = insert(:wallet)
      token = insert(:token)

      set_initial_balance(%{
        address: wallet1.address,
        token: token,
        amount: 200_000
      })

      client_request("/me.transfer", %{
        idempotency_token: UUID.generate(),
        to_address: wallet2.address,
        token_id: token.id,
        amount: 100_000
      })

      transfer = get_last_inserted(Transfer)
      assert transfer.from == wallet1.address
    end

    test "returns an invalid_parameter error if a parameter is missing" do
      response =
        client_request("/me.transfer", %{
          idempotency_token: UUID.generate(),
          token_id: "an_id",
          amount: 100_000
        })

      assert response == %{
               "success" => false,
               "version" => "1",
               "data" => %{
                 "code" => "client:invalid_parameter",
                 "description" => "Invalid parameter provided",
                 "messages" => nil,
                 "object" => "error"
               }
             }
    end
  end
end
