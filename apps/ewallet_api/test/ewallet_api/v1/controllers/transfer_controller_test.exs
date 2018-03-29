defmodule EWalletAPI.V1.TransferControllerTest do
  use EWalletAPI.ConnCase, async: true
  alias EWalletDB.{User, MintedToken, Account, Transfer}
  alias Ecto.UUID
  alias EWallet.Web.Date

  describe "/transfer" do
    test "returns idempotency error if header is not specified" do
      balance1 = insert(:balance)
      balance2 = insert(:balance)
      minted_token = insert(:minted_token)

      request_data = %{
        from_address: balance1.address,
        to_address: balance2.address,
        token_id: minted_token.friendly_id,
        amount: 1_000 * minted_token.subunit_to_unit,
        metadata: %{}
      }

      response = provider_request("/transfer", request_data)

      assert response == %{
        "success" => false,
        "version" => "1",
        "data" => %{
          "code" => "client:no_idempotency_token_provided",
          "description" =>
            "The call you made requires the Idempotency-Token header to prevent duplication.",
          "messages" => nil,
          "object" => "error"
        }
      }
    end

    test "updates the user balance and returns the updated amount" do
      account        = Account.get_master_account()
      master_balance = Account.get_primary_balance(account)
      balance1      = insert(:balance)
      balance2      = insert(:balance)
      minted_token   = insert(:minted_token)
      _mint          = mint!(minted_token)

      transfer!(master_balance.address, balance1.address,
                minted_token, 200_000 * minted_token.subunit_to_unit)

      response = provider_request_with_idempotency("/transfer", UUID.generate(), %{
        from_address: balance1.address,
        to_address: balance2.address,
        token_id: minted_token.friendly_id,
        amount: 100_000 * minted_token.subunit_to_unit,
        metadata: %{something: "interesting"},
        encrypted_metadata: %{something: "secret"}
      })

      transfer = get_last_inserted(Transfer)
      assert transfer.metadata == %{"something" => "interesting"}
      assert transfer.encrypted_metadata == %{"something" => "secret"}

      assert response == %{
        "success" => true,
        "version" => "1",
        "data" => %{
          "object" => "list",
          "data" => [
            %{
              "object" => "address",
              "socket_topic" => "address:#{balance1.address}",
              "address" => balance1.address,
              "balances" => [
                %{
                  "object" => "balance",
                  "amount" => 100_000 * minted_token.subunit_to_unit,
                  "minted_token" => %{
                    "name" => minted_token.name,
                    "object" => "minted_token",
                    "subunit_to_unit" => 100,
                    "id" => minted_token.friendly_id,
                    "symbol" => minted_token.symbol,
                    "metadata" => %{},
                    "encrypted_metadata" => %{},
                    "created_at" => Date.to_iso8601(minted_token.inserted_at),
                    "updated_at" => Date.to_iso8601(minted_token.updated_at)
                  }
                }
              ]
            },
            %{
              "object" => "address",
              "socket_topic" => "address:#{balance2.address}",
              "address" => balance2.address,
              "balances" => [
                %{
                  "object" => "balance",
                  "amount" => 100_000 * minted_token.subunit_to_unit,
                  "minted_token" => %{
                    "id" => minted_token.friendly_id,
                    "name" => minted_token.name,
                    "object" => "minted_token",
                    "subunit_to_unit" => 100,
                    "symbol" => minted_token.symbol,
                    "metadata" => %{},
                    "encrypted_metadata" => %{},
                    "created_at" => Date.to_iso8601(minted_token.inserted_at),
                    "updated_at" => Date.to_iso8601(minted_token.updated_at)
                  },
                }
              ]
            }
          ]
        }
      }
    end

    test "returns a 'same_address' error when the addresses are the same" do
      balance      = insert(:balance)
      minted_token   = insert(:minted_token)

      response = provider_request_with_idempotency("/transfer", UUID.generate(), %{
         from_address: balance.address,
         to_address: balance.address,
         token_id: minted_token.friendly_id,
         amount: 100_000 * minted_token.subunit_to_unit,
         metadata: %{}
       })

      assert response == %{
        "success" => false,
        "version" => "1",
        "data" => %{
          "code" => "transaction:same_address",
          "description" => "Found identical addresses in senders and receivers: #{balance.address}.",
          "messages" => nil,
          "object" => "error"
        }
      }
    end

    test "returns insufficient_funds when the user is too poor" do
      balance1      = insert(:balance)
      balance2      = insert(:balance)
      minted_token   = insert(:minted_token)

      response = provider_request_with_idempotency("/transfer", UUID.generate(), %{
         from_address: balance1.address,
         to_address: balance2.address,
         token_id: minted_token.friendly_id,
         amount: 100_000 * minted_token.subunit_to_unit,
         metadata: %{}
       })

      assert response == %{
        "success" => false,
        "version" => "1",
        "data" => %{
          "code" => "transaction:insufficient_funds",
          "description" => "The specified balance (#{balance1.address}) does not " <>
          "contain enough funds. Available: 0.0 #{minted_token.friendly_id} - " <>
          "Attempted debit: 100000.0 #{minted_token.friendly_id}",
          "messages" => nil,
          "object" => "error"
        }
      }
    end

    test "returns from_address_not_found when the from balance is not found" do
      balance = insert(:balance)
      minted_token = insert(:minted_token)

      response = provider_request_with_idempotency("/transfer", UUID.generate(), %{
        from_address: "00000000-0000-0000-0000-000000000000",
        to_address: balance.address,
        token_id: minted_token.friendly_id,
        amount: 100_000,
        metadata: %{}
      })

      assert response == %{
       "success" => false,
       "version" => "1",
       "data" => %{
         "code" => "user:from_address_not_found",
         "description" =>
           "No balance found for the provided from_address.",
         "messages" => nil,
         "object" => "error"
       }}
    end

    test "returns to_address_not_found when the to balance is not found" do
      balance = insert(:balance)
      minted_token = insert(:minted_token)

      response = provider_request_with_idempotency("/transfer", UUID.generate(), %{
        from_address: balance.address,
        to_address: "00000000-0000-0000-0000-000000000000",
        token_id: minted_token.friendly_id,
        amount: 100_000,
        metadata: %{}
      })

      assert response == %{
       "success" => false,
       "version" => "1",
       "data" => %{
         "code" => "user:to_address_not_found",
         "description" =>
           "No balance found for the provided to_address.",
         "messages" => nil,
         "object" => "error"
       }}
    end

    test "returns minted_token_not_found when the minted token is not found" do
      balance1 = insert(:balance)
      balance2 = insert(:balance)

      response = provider_request_with_idempotency("/transfer", UUID.generate(), %{
        from_address: balance1.address,
        to_address: balance2.address,
        token_id: "BTC:456",
        amount: 100_000,
        metadata: %{}
      })

      assert response == %{
        "success" => false,
        "version" => "1",
        "data" => %{
          "code" => "minted_token:minted_token_not_found",
          "description" =>
            "There is no minted token matching the provided token_id.",
          "messages" => nil,
          "object" => "error"
        }}
    end
  end

  describe "/user.credit_balance" do
    test "returns idempotency error if header is not specified" do
      {:ok, user} = :user |> params_for() |> User.insert()
      {:ok, minted_token} = :minted_token |> params_for() |> MintedToken.insert()

      response = provider_request("/user.credit_balance", %{
        provider_user_id: user.provider_user_id,
        token_id: minted_token.friendly_id,
        amount: 100_000,
        metadata: %{}
      })

      assert response == %{
        "success" => false,
        "version" => "1",
        "data" => %{
          "code" => "client:no_idempotency_token_provided",
          "description" =>
            "The call you made requires the Idempotency-Token header to prevent duplication.",
          "messages" => nil,
          "object" => "error"
        }
      }
    end

    test "updates the user balance and returns the updated amount" do
      {:ok, user}    = :user |> params_for() |> User.insert()
      user_balance   = User.get_primary_balance(user)
      account        = Account.get_master_account()
      minted_token   = insert(:minted_token, account: account)
      _mint          = mint!(minted_token)

      response = provider_request_with_idempotency("/user.credit_balance", UUID.generate(), %{
        provider_user_id: user.provider_user_id,
        token_id: minted_token.friendly_id,
        amount: 1_000 * minted_token.subunit_to_unit,
        metadata: %{something: "interesting"},
        encrypted_metadata: %{something: "secret"}
      })

      transfer = get_last_inserted(Transfer)
      assert transfer.metadata == %{"something" => "interesting"}
      assert transfer.encrypted_metadata == %{"something" => "secret"}

      assert response == %{
        "success" => true,
        "version" => "1",
        "data" => %{
          "object" => "list",
          "data" => [
            %{
              "object" => "address",
              "socket_topic" => "address:#{user_balance.address}",
              "address" => user_balance.address,
              "balances" => [
                %{
                  "object" => "balance",
                  "amount" => 1_000 * minted_token.subunit_to_unit,
                  "minted_token" => %{
                    "name" => minted_token.name,
                    "object" => "minted_token",
                    "subunit_to_unit" => 100,
                    "id" => minted_token.friendly_id,
                    "symbol" => minted_token.symbol,
                    "metadata" => %{},
                    "encrypted_metadata" => %{},
                    "created_at" => Date.to_iso8601(minted_token.inserted_at),
                    "updated_at" => Date.to_iso8601(minted_token.updated_at)
                  }
                }
              ]
            }
          ]
        }
      }
    end

    test "returns invalid_parameter when the provider_user_id is missing" do
      {:ok, minted_token} = :minted_token |> params_for() |> MintedToken.insert()

      response = provider_request_with_idempotency("/user.credit_balance", UUID.generate(), %{
        token_id: minted_token.friendly_id,
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
        }}
    end

    test "returns user_not_found when the user is not found" do
      {:ok, account} = :account |> params_for() |> Account.insert()
      {:ok, minted_token} = :minted_token |> params_for(account: account) |> MintedToken.insert()

      response = provider_request_with_idempotency("/user.credit_balance", UUID.generate(), %{
        provider_user_id: "fake",
        token_id: minted_token.friendly_id,
        amount: 100_000,
        metadata: %{}
      })

      assert response == %{
        "success" => false,
        "version" => "1",
        "data" => %{
          "code" => "user:provider_user_id_not_found",
          "description" =>
            "There is no user corresponding to the provided " <>
            "provider_user_id",
          "messages" => nil,
          "object" => "error"
        }}
    end

    test "returns account_id when the account is not found" do
      {:ok, user} = :user |> params_for() |> User.insert()
      {:ok, minted_token} = :minted_token |> params_for() |> MintedToken.insert()

      response = provider_request_with_idempotency("/user.credit_balance", UUID.generate(), %{
        provider_user_id: user.provider_user_id,
        token_id: minted_token.friendly_id,
        amount: 100_000,
        account_id: "00000000-0000-0000-0000-000000000000",
        metadata: %{}
      })

      assert response == %{
        "success" => false,
        "version" => "1",
        "data" => %{
          "code" => "user:account_id_not_found",
          "description" => "There is no account corresponding to the provided account_id",
          "messages" => nil, "object" => "error"
        }
      }
    end

    test "returns minted_token_not_found when the minted token is not found" do
      {:ok, user} = :user |> params_for() |> User.insert()
      {:ok, account} = :account |> params_for() |> Account.insert()

      response = provider_request_with_idempotency("/user.credit_balance", UUID.generate(), %{
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
          "code" => "minted_token:minted_token_not_found",
          "description" =>
            "There is no minted token matching the provided token_id.",
          "messages" => nil,
          "object" => "error"
        }}
    end
  end

  describe "/user.debit_balance" do
    test "returns idempotency error if header is not specified" do
      {:ok, user} = :user |> params_for() |> User.insert()
      {:ok, account} = :account |> params_for() |> Account.insert()
      {:ok, minted_token} = :minted_token |> params_for(account: account) |> MintedToken.insert()

       response = provider_request("/user.debit_balance", %{
        provider_user_id: user.provider_user_id,
        token_id: minted_token.friendly_id,
        amount: 100_000,
        metadata: %{}
      })

      assert response == %{
        "success" => false,
        "version" => "1",
        "data" => %{
          "code" => "client:no_idempotency_token_provided",
          "description" =>
            "The call you made requires the Idempotency-Token header to prevent duplication.",
          "messages" => nil,
          "object" => "error"
        }
      }
    end

    test "returns insufficient_funds when the user is too poor" do
      {:ok, account} = :account |> params_for() |> Account.insert()
      {:ok, user} = :user |> params_for() |> User.insert()
      user_balance   = User.get_primary_balance(user)
      {:ok, minted_token} = :minted_token |> params_for(account: account) |> MintedToken.insert()

      response = provider_request_with_idempotency("/user.debit_balance", UUID.generate(), %{
        provider_user_id: user.provider_user_id,
        token_id: minted_token.friendly_id,
        amount: 100_000,
        metadata: %{}
      })

      assert response == %{
        "success" => false,
        "version" => "1",
        "data" => %{
          "code" => "transaction:insufficient_funds",
          "description" => "The specified balance (#{user_balance.address})" <>
          " does not contain enough funds. Available: 0.0 " <>
          "#{minted_token.friendly_id} - Attempted debit: 1000.0 " <>
          "#{minted_token.friendly_id}",
          "messages" => nil,
          "object" => "error"
        }
      }
    end

    test "returns the updated balances when the user has enough funds" do
      account = Account.get_master_account()
      master_balance = Account.get_primary_balance(account)
      {:ok, user} = :user |> params_for() |> User.insert()
      user_balance   = User.get_primary_balance(user)
      {:ok, minted_token} = :minted_token |> params_for(account: account) |> MintedToken.insert()
      mint!(minted_token)

      transfer!(master_balance.address, user_balance.address,
                minted_token, 200_000 * minted_token.subunit_to_unit)

      response = provider_request_with_idempotency("/user.debit_balance", UUID.generate(), %{
        provider_user_id: user.provider_user_id,
        token_id: minted_token.friendly_id,
        amount: 150_000 * minted_token.subunit_to_unit,
        metadata: %{something: "interesting"},
        encrypted_metadata: %{something: "secret"}
      })

      transfer = get_last_inserted(Transfer)
      assert transfer.metadata == %{"something" => "interesting"}
      assert transfer.encrypted_metadata == %{"something" => "secret"}

      address = User.get_primary_balance(user).address
      assert response == %{
        "version" => "1",
        "success" => true,
        "data" => %{
          "object" => "list",
          "data" => [
            %{
              "object" => "address",
              "socket_topic" => "address:#{address}",
              "address" => address,
              "balances" => [
                %{
                  "object" => "balance",
                  "amount" => 50_000 * minted_token.subunit_to_unit,
                  "minted_token" => %{
                    "name" => minted_token.name,
                    "object" => "minted_token",
                    "subunit_to_unit" => 100,
                    "symbol" => minted_token.symbol,
                    "id" => minted_token.friendly_id,
                    "metadata" => %{},
                    "encrypted_metadata" => %{},
                    "created_at" => Date.to_iso8601(minted_token.inserted_at),
                    "updated_at" => Date.to_iso8601(minted_token.updated_at)
                  }
                }
              ]
            }
          ]
        }
      }
    end
  end
end
