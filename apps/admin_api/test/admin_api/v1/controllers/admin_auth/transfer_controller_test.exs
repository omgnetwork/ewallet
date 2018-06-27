defmodule AdminAPI.V1.AdminAuth.TransferControllerTest do
  use AdminAPI.ConnCase, async: true
  alias EWalletDB.{User, Token, Account, Transaction}
  alias Ecto.UUID
  alias EWallet.Web.Date
  alias EWallet.Web.V1.UserSerializer

  describe "/transfer" do
    test "returns idempotency error if header is not specified" do
      wallet1 = insert(:wallet)
      wallet2 = insert(:wallet)
      token = insert(:token)

      request_data = %{
        from_address: wallet1.address,
        to_address: wallet2.address,
        token_id: token.id,
        amount: 1_000 * token.subunit_to_unit,
        metadata: %{}
      }

      response = admin_user_request("/transfer", request_data)

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

    test "updates the user wallet and returns the updated amount" do
      account = Account.get_master_account()
      master_wallet = Account.get_primary_wallet(account)
      wallet1 = insert(:wallet, name: "name0")
      wallet2 = insert(:wallet, name: "name1")
      token = insert(:token)
      _mint = mint!(token)

      transfer!(
        master_wallet.address,
        wallet1.address,
        token,
        200_000 * token.subunit_to_unit
      )

      response =
        admin_user_request("/transfer", %{
          idempotency_token: UUID.generate(),
          from_address: wallet1.address,
          to_address: wallet2.address,
          token_id: token.id,
          amount: 100_000 * token.subunit_to_unit,
          metadata: %{something: "interesting"},
          encrypted_metadata: %{something: "secret"}
        })

      transaction = get_last_inserted(Transaction)
      assert transaction.metadata == %{"something" => "interesting"}
      assert transaction.encrypted_metadata == %{"something" => "secret"}

      assert response == %{
               "success" => true,
               "version" => "1",
               "data" => %{
                 "object" => "list",
                 "data" => [
                   %{
                     "object" => "wallet",
                     "socket_topic" => "wallet:#{wallet1.address}",
                     "address" => wallet1.address,
                     "encrypted_metadata" => %{},
                     "identifier" => "primary",
                     "metadata" => %{},
                     "name" => "name0",
                     "account" => nil,
                     "account_id" => nil,
                     "user" => wallet1.user |> UserSerializer.serialize() |> stringify_keys(),
                     "user_id" => wallet1.user.id,
                     "created_at" => Date.to_iso8601(wallet1.inserted_at),
                     "updated_at" => Date.to_iso8601(wallet1.updated_at),
                     "balances" => [
                       %{
                         "object" => "balance",
                         "amount" => 100_000 * token.subunit_to_unit,
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
                       }
                     ]
                   },
                   %{
                     "object" => "wallet",
                     "socket_topic" => "wallet:#{wallet2.address}",
                     "address" => wallet2.address,
                     "encrypted_metadata" => %{},
                     "identifier" => "primary",
                     "metadata" => %{},
                     "name" => "name1",
                     "account" => nil,
                     "account_id" => nil,
                     "user" => wallet2.user |> UserSerializer.serialize() |> stringify_keys(),
                     "user_id" => wallet2.user.id,
                     "created_at" => Date.to_iso8601(wallet2.inserted_at),
                     "updated_at" => Date.to_iso8601(wallet2.updated_at),
                     "balances" => [
                       %{
                         "object" => "balance",
                         "amount" => 100_000 * token.subunit_to_unit,
                         "token" => %{
                           "id" => token.id,
                           "name" => token.name,
                           "object" => "token",
                           "subunit_to_unit" => 100,
                           "symbol" => token.symbol,
                           "metadata" => %{},
                           "encrypted_metadata" => %{},
                           "created_at" => Date.to_iso8601(token.inserted_at),
                           "updated_at" => Date.to_iso8601(token.updated_at)
                         }
                       }
                     ]
                   }
                 ]
               }
             }
    end

    test "returns a 'same_address' error when the addresses are the same" do
      wallet = insert(:wallet)
      token = insert(:token)

      response =
        admin_user_request("/transfer", %{
          idempotency_token: UUID.generate(),
          from_address: wallet.address,
          to_address: wallet.address,
          token_id: token.id,
          amount: 100_000 * token.subunit_to_unit,
          metadata: %{}
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

    test "returns insufficient_funds when the user is too poor" do
      wallet1 = insert(:wallet)
      wallet2 = insert(:wallet)
      token = insert(:token)

      response =
        admin_user_request("/transfer", %{
          idempotency_token: UUID.generate(),
          from_address: wallet1.address,
          to_address: wallet2.address,
          token_id: token.id,
          amount: 100_000 * token.subunit_to_unit,
          metadata: %{}
        })

      assert response == %{
               "success" => false,
               "version" => "1",
               "data" => %{
                 "code" => "transaction:insufficient_funds",
                 "description" =>
                   "The specified wallet (#{wallet1.address}) does not " <>
                     "contain enough funds. Available: 0 #{token.id} - " <>
                     "Attempted debit: 100000 #{token.id}",
                 "messages" => nil,
                 "object" => "error"
               }
             }
    end

    test "returns from_address_not_found when the from wallet is not found" do
      wallet = insert(:wallet)
      token = insert(:token)

      response =
        admin_user_request("/transfer", %{
          idempotency_token: UUID.generate(),
          from_address: "00000000-0000-0000-0000-000000000000",
          to_address: wallet.address,
          token_id: token.id,
          amount: 100_000,
          metadata: %{}
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

    test "returns to_address_not_found when the to wallet is not found" do
      wallet = insert(:wallet)
      token = insert(:token)

      response =
        admin_user_request("/transfer", %{
          idempotency_token: UUID.generate(),
          from_address: wallet.address,
          to_address: "00000000-0000-0000-0000-000000000000",
          token_id: token.id,
          amount: 100_000,
          metadata: %{}
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
      wallet1 = insert(:wallet)
      wallet2 = insert(:wallet)

      response =
        admin_user_request("/transfer", %{
          idempotency_token: UUID.generate(),
          from_address: wallet1.address,
          to_address: wallet2.address,
          token_id: "BTC:456",
          amount: 100_000,
          metadata: %{}
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
  end

  describe "/user.credit_wallet" do
    test "returns idempotency error if header is not specified" do
      {:ok, user} = :user |> params_for() |> User.insert()
      {:ok, token} = :token |> params_for() |> Token.insert()

      response =
        admin_user_request("/user.credit_wallet", %{
          provider_user_id: user.provider_user_id,
          token_id: token.id,
          amount: 100_000,
          metadata: %{}
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

    test "updates the user wallet and returns the updated amount" do
      {:ok, user} = :user |> params_for() |> User.insert()
      user_wallet = User.get_primary_wallet(user)
      account = Account.get_master_account()
      token = insert(:token, account: account)
      _mint = mint!(token)

      response =
        admin_user_request("/user.credit_wallet", %{
          idempotency_token: UUID.generate(),
          account_id: account.id,
          provider_user_id: user.provider_user_id,
          token_id: token.id,
          amount: 1_000 * token.subunit_to_unit,
          metadata: %{something: "interesting"},
          encrypted_metadata: %{something: "secret"}
        })

      assert response == %{
               "success" => true,
               "version" => "1",
               "data" => %{
                 "object" => "list",
                 "data" => [
                   %{
                     "object" => "wallet",
                     "socket_topic" => "wallet:#{user_wallet.address}",
                     "address" => user_wallet.address,
                     "account" => nil,
                     "account_id" => nil,
                     "encrypted_metadata" => %{},
                     "identifier" => "primary",
                     "metadata" => %{},
                     "name" => "primary",
                     "user" => user |> UserSerializer.serialize() |> stringify_keys(),
                     "user_id" => user.id,
                     "created_at" => Date.to_iso8601(user_wallet.inserted_at),
                     "updated_at" => Date.to_iso8601(user_wallet.updated_at),
                     "balances" => [
                       %{
                         "object" => "balance",
                         "amount" => 1_000 * token.subunit_to_unit,
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
                       }
                     ]
                   }
                 ]
               }
             }

      transaction = get_last_inserted(Transaction)
      assert transaction.metadata == %{"something" => "interesting"}
      assert transaction.encrypted_metadata == %{"something" => "secret"}
    end

    test "returns invalid_parameter when the provider_user_id is missing" do
      {:ok, token} = :token |> params_for() |> Token.insert()

      response =
        admin_user_request("/user.credit_wallet", %{
          idempotency_token: UUID.generate(),
          token_id: token.id,
          amount: 100_000,
          metadata: %{}
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

    test "returns user_not_found when the user is not found" do
      {:ok, account} = :account |> params_for() |> Account.insert()
      {:ok, token} = :token |> params_for(account: account) |> Token.insert()

      response =
        admin_user_request("/user.credit_wallet", %{
          idempotency_token: UUID.generate(),
          account_id: account.id,
          provider_user_id: "fake",
          token_id: token.id,
          amount: 100_000,
          metadata: %{}
        })

      assert response == %{
               "success" => false,
               "version" => "1",
               "data" => %{
                 "code" => "user:provider_user_id_not_found",
                 "description" =>
                   "There is no user corresponding to the provided " <> "provider_user_id",
                 "messages" => nil,
                 "object" => "error"
               }
             }
    end

    test "returns account_id when the account is not found" do
      {:ok, user} = :user |> params_for() |> User.insert()
      {:ok, token} = :token |> params_for() |> Token.insert()

      response =
        admin_user_request("/user.credit_wallet", %{
          idempotency_token: UUID.generate(),
          provider_user_id: user.provider_user_id,
          token_id: token.id,
          amount: 100_000,
          account_id: "acc_12345678901234567890123456",
          metadata: %{}
        })

      assert response == %{
               "success" => false,
               "version" => "1",
               "data" => %{
                 "code" => "account:id_not_found",
                 "description" => "There is no account corresponding to the provided id",
                 "messages" => nil,
                 "object" => "error"
               }
             }
    end

    test "returns token_not_found when the token is not found" do
      {:ok, user} = :user |> params_for() |> User.insert()
      {:ok, account} = :account |> params_for() |> Account.insert()

      response =
        admin_user_request("/user.credit_wallet", %{
          idempotency_token: UUID.generate(),
          provider_user_id: user.provider_user_id,
          token_id: "BTC:456",
          amount: 100_000,
          metadata: %{},
          account_id: account.id
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
  end

  describe "/user.debit_wallet" do
    test "returns idempotency error if header is not specified" do
      {:ok, user} = :user |> params_for() |> User.insert()
      {:ok, account} = :account |> params_for() |> Account.insert()
      {:ok, token} = :token |> params_for(account: account) |> Token.insert()

      response =
        admin_user_request("/user.debit_wallet", %{
          account_id: account.id,
          provider_user_id: user.provider_user_id,
          token_id: token.id,
          amount: 100_000,
          metadata: %{}
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

    test "returns insufficient_funds when the user is too poor :~(" do
      {:ok, account} = :account |> params_for() |> Account.insert()
      {:ok, user} = :user |> params_for() |> User.insert()
      user_wallet = User.get_primary_wallet(user)
      {:ok, token} = :token |> params_for(account: account) |> Token.insert()

      response =
        admin_user_request("/user.debit_wallet", %{
          idempotency_token: UUID.generate(),
          account_id: account.id,
          provider_user_id: user.provider_user_id,
          token_id: token.id,
          amount: 100_000,
          metadata: %{}
        })

      assert response == %{
               "success" => false,
               "version" => "1",
               "data" => %{
                 "code" => "transaction:insufficient_funds",
                 "description" =>
                   "The specified wallet (#{user_wallet.address})" <>
                     " does not contain enough funds. Available: 0 " <>
                     "#{token.id} - Attempted debit: 1000 " <> "#{token.id}",
                 "messages" => nil,
                 "object" => "error"
               }
             }
    end

    test "returns the updated wallets when the user has enough funds" do
      account = Account.get_master_account()
      master_wallet = Account.get_primary_wallet(account)
      {:ok, user} = :user |> params_for() |> User.insert()
      user_wallet = User.get_primary_wallet(user)
      {:ok, token} = :token |> params_for(account: account) |> Token.insert()
      mint!(token)

      transfer!(
        master_wallet.address,
        user_wallet.address,
        token,
        200_000 * token.subunit_to_unit
      )

      response =
        admin_user_request("/user.debit_wallet", %{
          idempotency_token: UUID.generate(),
          account_id: account.id,
          provider_user_id: user.provider_user_id,
          token_id: token.id,
          amount: 150_000 * token.subunit_to_unit,
          metadata: %{something: "interesting"},
          encrypted_metadata: %{something: "secret"}
        })

      assert response == %{
               "version" => "1",
               "success" => true,
               "data" => %{
                 "object" => "list",
                 "data" => [
                   %{
                     "object" => "wallet",
                     "socket_topic" => "wallet:#{user_wallet.address}",
                     "address" => user_wallet.address,
                     "account" => nil,
                     "account_id" => nil,
                     "encrypted_metadata" => %{},
                     "identifier" => "primary",
                     "metadata" => %{},
                     "name" => "primary",
                     "created_at" => Date.to_iso8601(user_wallet.inserted_at),
                     "updated_at" => Date.to_iso8601(user_wallet.updated_at),
                     "user" => %{
                       "avatar" => %{
                         "large" => nil,
                         "original" => nil,
                         "small" => nil,
                         "thumb" => nil
                       },
                       "created_at" => Date.to_iso8601(user.inserted_at),
                       "email" => nil,
                       "encrypted_metadata" => %{},
                       "id" => user.id,
                       "metadata" => user.metadata,
                       "object" => "user",
                       "provider_user_id" => user.provider_user_id,
                       "socket_topic" => "user:#{user.id}",
                       "updated_at" => Date.to_iso8601(user.updated_at),
                       "username" => user.username
                     },
                     "user_id" => user.id,
                     "balances" => [
                       %{
                         "object" => "balance",
                         "amount" => 50_000 * token.subunit_to_unit,
                         "token" => %{
                           "name" => token.name,
                           "object" => "token",
                           "subunit_to_unit" => 100,
                           "symbol" => token.symbol,
                           "id" => token.id,
                           "metadata" => %{},
                           "encrypted_metadata" => %{},
                           "created_at" => Date.to_iso8601(token.inserted_at),
                           "updated_at" => Date.to_iso8601(token.updated_at)
                         }
                       }
                     ]
                   }
                 ]
               }
             }

      transaction = get_last_inserted(Transaction)
      assert transaction.metadata == %{"something" => "interesting"}
      assert transaction.encrypted_metadata == %{"something" => "secret"}
    end
  end
end
