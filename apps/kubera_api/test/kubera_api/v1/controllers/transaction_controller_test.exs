defmodule KuberaAPI.V1.TransactionControllerTest do
  use KuberaAPI.ConnCase, async: true
  import Mock
  alias KuberaDB.{User, MintedToken, Account}
  alias KuberaMQ.{Entry, Balance}

  def valid_response do
    {:ok, %{
      "correlation_id" => "d63071c7-2042-4913-af6f-f3e363521434",
      "id" => "889f0ec8-9038-424c-8e25-1d19290dee9b",
      "inserted_at" => "2017-11-01T06:42:58.004972",
      "metadata" => "{}",
      "object" => "entry",
      "transactions" => [
        %{
          "amount" => 100_000,
          "balance_address" => "dda0b902-0a37-4ecf-bb96-e81e89db3d2b",
          "id" => "688b8e65-248a-48ce-a7c6-ad593f7c56b2",
          "inserted_at" => "2017-11-01T06:42:58.043203",
          "minted_token_friendly_id" => "OMG:123",
          "object" => "transaction",
          "type" => "debit"
        },
        %{
          "amount" => 100_000,
          "balance_address" => "5b54d25e-8411-4ea7-ac65-9eeed311a6a2",
          "id" => "f1ba0a6a-fbea-4ede-bf69-8b2d127b92c2",
          "inserted_at" => "2017-11-01T06:42:58.044764",
          "minted_token_friendly_id" => "OMG:123",
          "object" => "transaction",
          "type" => "credit"
        }
      ]
   }}
  end

  def valid_balances_response do
    {:ok, %{
      "object" => "balance",
      "address" => "master",
      "amounts" => %{"BTC:123" => 9850}
    }}
  end

  def enough_funds_response do
    {:ok, %{}}
  end

  def insufficient_funds_response do
    {:error, "client:insufficient_funds", "Description"}
  end

  describe "/transfer" do
    test "returns idempotency error if header is not specified" do
      balance1 = insert(:balance)
      balance2 = insert(:balance)
      minted_token = insert(:minted_token)

      request_data = %{
        from_address: balance1.address,
        to_address: balance2.address,
        token_id: minted_token.friendly_id,
        amount: 100_000,
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
      with_mocks [
        {Entry, [], [insert: fn _data, _idempotency_token -> valid_response() end]},
        {
          Balance,
          [],
          [get: fn _symbol, _address -> {:ok, %{
            "object" => "balance",
            "address" => "master",
            "amounts" => %{
              "BTC:123" => 9850
            }
          }} end]
        }
      ] do
        balance1 = insert(:balance, address: "123")
        balance2 = insert(:balance, address: "456")
        minted_token = insert(:minted_token, friendly_id: "BTC:123", symbol: "BTC")

        request_data = %{
          from_address: balance1.address,
          to_address: balance2.address,
          token_id: minted_token.friendly_id,
          amount: 100_000,
          metadata: %{}
        }

        response = provider_request_with_idempotency("/transfer",
                                                     "5b688e97-8c0f-48af-943c-10b6f812c4f4",
                                                     request_data)

        assert response == %{
          "success" => true,
          "version" => "1",
          "data" => %{
            "object" => "list",
            "data" => [
              %{
                "object" => "address",
                "address" => balance1.address,
                "balances" => [
                  %{
                    "object" => "balance",
                    "amount" => 9850,
                    "minted_token" => %{
                      "name" => minted_token.name,
                      "object" => "minted_token",
                      "subunit_to_unit" => 100,
                      "id" => "BTC:123",
                      "symbol" => "BTC"
                    }
                  }
                ]
              },
              %{
                "object" => "address",
                "address" => balance2.address,
                "balances" => [
                  %{
                    "object" => "balance",
                    "amount" => 9850,
                    "minted_token" => %{
                      "id" => "BTC:123",
                      "name" => minted_token.name,
                      "object" => "minted_token",
                      "subunit_to_unit" => 100,
                      "symbol" => "BTC"
                    },
                  }
                ]
              }
            ]
          }
        }
      end
    end

    test "returns insufficient_funds when the user is too poor" do
      with_mocks [
        {Entry, [], [insert: fn _data, _idempotency_token -> insufficient_funds_response() end]},
        {
          Balance,
          [],
          [get: fn _symbol, _address -> valid_balances_response() end]
        }
        ] do
          balance1 = insert(:balance, address: "123")
          balance2 = insert(:balance, address: "456")
          minted_token = insert(:minted_token, friendly_id: "BTC:123", symbol: "BTC")

          request_data = %{
            from_address: balance1.address,
            to_address: balance2.address,
            token_id: minted_token.friendly_id,
            amount: 100_000,
            metadata: %{}
          }

          response = provider_request_with_idempotency("/transfer",
                                                       "5b688e97-8c0f-48af-943c-10b6f812c4f4",
                                                       request_data)
          assert response == %{
            "success" => false,
            "version" => "1",
            "data" => %{
              "code" => "client:insufficient_funds",
              "description" => "Description",
              "messages" => nil,
              "object" => "error"
            }
          }
      end
    end

    test "returns from_address_not_found when the from balance is not found" do
      with_mocks [
        {Entry, [], [insert: fn _data, _idempotency_token -> valid_response() end]},
        {
          Balance,
          [],
          [get: fn _symbol, _address -> valid_balances_response() end]
        }
      ] do
        balance = insert(:balance, address: "456")
        minted_token = insert(:minted_token, friendly_id: "BTC:123", symbol: "BTC")

        request_data = %{
          from_address: "123",
          to_address: balance.address,
          token_id: minted_token.friendly_id,
          amount: 100_000,
          metadata: %{}
        }

        response = provider_request_with_idempotency("/transfer",
                                                     "5b688e97-8c0f-48af-943c-10b6f812c4f4",
                                                     request_data)

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
    end

    test "returns to_address_not_found when the to balance is not found" do
      with_mocks [
        {Entry, [], [insert: fn _data, _idempotency_token -> valid_response() end]},
        {
          Balance,
          [],
          [get: fn _symbol, _address -> valid_balances_response() end]
        }
      ] do
        balance = insert(:balance, address: "456")
        minted_token = insert(:minted_token, friendly_id: "BTC:123", symbol: "BTC")

        request_data = %{
          from_address: balance.address,
          to_address: "123",
          token_id: minted_token.friendly_id,
          amount: 100_000,
          metadata: %{}
        }

        response = provider_request_with_idempotency("/transfer",
                                                     "5b688e97-8c0f-48af-943c-10b6f812c4f4",
                                                     request_data)

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
    end

    test "returns minted_token_not_found when the minted token is not found" do
      with_mocks [
        {Entry, [], [insert: fn _data, _idempotency_token -> valid_response() end]},
        {
          Balance,
          [],
          [get: fn _symbol, _address -> valid_balances_response() end]
        }
      ] do
        balance1 = insert(:balance, address: "123")
        balance2 = insert(:balance, address: "456")

        request_data = %{
          from_address: balance1.address,
          to_address: balance2.address,
          token_id: "BTC:456",
          amount: 100_000,
          metadata: %{}
        }

        response = provider_request_with_idempotency("/transfer",
                                                     "5b688e97-8c0f-48af-943c-10b6f812c4f4",
                                                     request_data)

        assert response == %{
          "success" => false,
          "version" => "1",
          "data" => %{
            "code" => "user:minted_token_not_found",
            "description" =>
              "There is no minted token matching the provided token_id.",
            "messages" => nil,
            "object" => "error"
          }}
      end
    end
  end

  describe "/user.credit_balance" do
    test "returns idempotency error if header is not specified" do
      {:ok, user} = :user |> params_for() |> User.insert()
      {:ok, minted_token} =
        :minted_token |> params_for(friendly_id: "BTC:123", symbol: "BTC") |> MintedToken.insert()

      request_data = %{
        provider_user_id: user.provider_user_id,
        token_id: minted_token.friendly_id,
        amount: 100_000,
        metadata: %{}
      }

      response = provider_request("/user.credit_balance", request_data)

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
      with_mocks [
        {Entry, [], [insert: fn _data, _idempotency_token -> valid_response() end]},
        {
          Balance,
          [],
          [get: fn _symbol, _address -> valid_balances_response() end]
        }
      ] do
          {:ok, user} = :user |> params_for() |> User.insert()
          {:ok, account} = :account |> params_for() |> Account.insert()
          {:ok, minted_token} =
            :minted_token
            |> params_for(account: account, friendly_id: "BTC:123", symbol: "BTC")
            |> MintedToken.insert()

          request_data = %{
            provider_user_id: user.provider_user_id,
            token_id: minted_token.friendly_id,
            amount: 100_000,
            metadata: %{}
          }

          response = provider_request_with_idempotency("/user.credit_balance",
                                                       "5b688e97-8c0f-48af-943c-10b6f812c4f4",
                                                       request_data)

          assert response == %{
            "success" => true,
            "version" => "1",
            "data" => %{
              "object" => "list",
              "data" => [
                %{
                  "object" => "address",
                  "address" => User.get_primary_balance(user).address,
                  "balances" => [
                    %{
                      "object" => "balance",
                      "amount" => 9850,
                      "minted_token" => %{
                        "name" => minted_token.name,
                        "object" => "minted_token",
                        "subunit_to_unit" => 100,
                        "id" => "BTC:123",
                        "symbol" => "BTC"
                      }
                    }
                  ]
                }
              ]
            }
          }
      end
    end

    test "returns invalid_parameter when the provider_user_id is missing" do
      with_mocks [
        {Entry, [], [insert: fn _data, _idempotency_token -> valid_response() end]},
        {
          Balance,
          [],
          [get: fn _symbol, _address -> valid_balances_response() end]
        }
      ] do
          {:ok, _} = :user |> params_for() |> User.insert()
          {:ok, minted_token} =
            :minted_token |> params_for(symbol: "BTC") |> MintedToken.insert()

          request_data = %{
            token_id: minted_token.friendly_id,
            amount: 100_000,
            metadata: %{}
          }

          response = provider_request_with_idempotency("/user.credit_balance",
                                                       "5b688e97-8c0f-48af-943c-10b6f812c4f4",
                                                       request_data)

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
    end

    test "returns user_not_found when the user is not found" do
      with_mocks [
        {Entry, [], [insert: fn _data, _idempotency_token -> valid_response() end]},
        {
          Balance,
          [],
          [get: fn _symbol, _address -> valid_balances_response() end]
        }
      ] do
          {:ok, account} = :account |> params_for() |> Account.insert()
          {:ok, minted_token} =
            :minted_token |> params_for(account: account, symbol: "BTC") |> MintedToken.insert()

          request_data = %{
            provider_user_id: "fake",
            token_id: minted_token.friendly_id,
            amount: 100_000,
            metadata: %{}
          }

          response = provider_request_with_idempotency("/user.credit_balance",
                                                       "5b688e97-8c0f-48af-943c-10b6f812c4f4",
                                                       request_data)

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
    end

    test "returns account_id when the account is not found" do
      with_mocks [
        {Entry, [], [insert: fn _data, _idempotency_token -> valid_response() end]},
        {
          Balance,
          [],
          [get: fn _symbol, _address -> valid_balances_response() end]
        }
      ] do
          {:ok, user} = :user |> params_for() |> User.insert()
          {:ok, minted_token} =
            :minted_token |> params_for(friendly_id: "BTC:123", symbol: "BTC") |> MintedToken.insert()

          request_data = %{
            provider_user_id: user.provider_user_id,
            token_id: minted_token.friendly_id,
            amount: 100_000,
            account_id: "123",
            metadata: %{}
          }

          response = provider_request_with_idempotency("/user.credit_balance",
                                                       "5b688e97-8c0f-48af-943c-10b6f812c4f4",
                                                       request_data)

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
    end

    test "returns minted_token_not_found when the minted token is not found" do
      with_mocks [
        {Entry, [], [insert: fn _data, _idempotency_token -> valid_response() end]},
        {
          Balance,
          [],
          [get: fn _symbol, _address -> valid_balances_response() end]
        }
      ] do
          {:ok, user} = :user |> params_for() |> User.insert()
          {:ok, account} = :account |> params_for() |> Account.insert()

          request_data = %{
            provider_user_id: user.provider_user_id,
            token_id: "BTC:456",
            amount: 100_000,
            metadata: %{},
            account_id: account.id
          }

          response = provider_request_with_idempotency("/user.credit_balance",
                                                       "5b688e97-8c0f-48af-943c-10b6f812c4f4",
                                                       request_data)

          assert response == %{
            "success" => false,
            "version" => "1",
            "data" => %{
              "code" => "user:minted_token_not_found",
              "description" =>
                "There is no minted token matching the provided token_id.",
              "messages" => nil,
              "object" => "error"
            }}
      end
    end
  end

  describe "/user.debit_balance" do
    test "returns idempotency error if header is not specified" do
      {:ok, user} = :user |> params_for() |> User.insert()
      {:ok, account} = :account |> params_for() |> Account.insert()
      {:ok, minted_token} =
        :minted_token |> params_for(account: account, symbol: "BTC") |> MintedToken.insert()

      request_data = %{
        provider_user_id: user.provider_user_id,
        token_id: minted_token.friendly_id,
        amount: 100_000,
        metadata: %{}
      }

      response = provider_request("/user.debit_balance", request_data)

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
      with_mocks [
        {Entry, [], [insert: fn _data, _idempotency_token -> insufficient_funds_response() end]},
        {
          Balance,
          [],
          [get: fn _symbol, _address -> valid_balances_response() end]
        }
        ] do
          {:ok, account} = :account |> params_for() |> Account.insert()
          {:ok, user} = :user |> params_for() |> User.insert()
          {:ok, minted_token} =
            :minted_token |> params_for(account: account, symbol: "BTC") |> MintedToken.insert()

          request_data = %{
            provider_user_id: user.provider_user_id,
            token_id: minted_token.friendly_id,
            amount: 100_000,
            metadata: %{}
          }

          response = provider_request_with_idempotency("/user.debit_balance",
                                                       "5b688e97-8c0f-48af-943c-10b6f812c4f4",
                                                       request_data)
          assert response == %{
            "success" => false,
            "version" => "1",
            "data" => %{
              "code" => "client:insufficient_funds",
              "description" => "Description",
              "messages" => nil,
              "object" => "error"
            }
          }
      end
    end

    test "returns the updated balances when the user has enough funds" do
      with_mocks [
        {Entry, [], [insert: fn _data, _idempotency_token -> enough_funds_response() end]},
        {
          Balance,
          [],
          [get: fn _symbol, _address -> valid_balances_response() end]
        }
      ] do
          {:ok, account} = :account |> params_for() |> Account.insert()
          {:ok, user} = :user |> params_for() |> User.insert()
          {:ok, minted_token} =
            :minted_token
            |> params_for(account: account, friendly_id: "BTC:123", symbol: "BTC")
            |> MintedToken.insert()

          request_data = %{
            provider_user_id: user.provider_user_id,
            token_id: minted_token.friendly_id,
            amount: 100_000,
            metadata: %{}
          }

          response = provider_request_with_idempotency("/user.debit_balance",
                                                       "5b688e97-8c0f-48af-943c-10b6f812c4f4",
                                                       request_data)
          assert response == %{
            "version" => "1",
            "success" => true,
            "data" => %{
              "object" => "list",
              "data" => [
                %{
                  "object" => "address",
                  "address" => User.get_primary_balance(user).address,
                  "balances" => [
                    %{
                      "object" => "balance",
                      "amount" => 9850,
                      "minted_token" => %{
                        "name" => minted_token.name,
                        "object" => "minted_token",
                        "subunit_to_unit" => 100,
                        "symbol" => "BTC",
                        "id" => minted_token.friendly_id,
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
end
