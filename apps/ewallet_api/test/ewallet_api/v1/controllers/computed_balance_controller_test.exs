defmodule EWalletAPI.V1.ComputedBalanceControllerTest do
  use EWalletAPI.ConnCase, async: true
  alias EWallet.Web.Date
  alias EWalletDB.{User, MintedToken, Account}

  describe "/all" do
    test "Get all user balances from its provider_user_id" do
      account = Account.get_master_account()
      master_balance = Account.get_primary_balance(account)
      {:ok, user} = :user |> params_for() |> User.insert()
      user_balance   = User.get_primary_balance(user)
      {:ok, btc} = :minted_token |> params_for(symbol: "BTC") |> MintedToken.insert()
      {:ok, omg} = :minted_token |> params_for(symbol: "OMG") |> MintedToken.insert()

      mint!(btc)
      mint!(omg)

      transfer!(master_balance.address, user_balance.address, btc, 150_000 * btc.subunit_to_unit)
      transfer!(master_balance.address, user_balance.address, omg, 12_000 * omg.subunit_to_unit)

      response = provider_request("/user.list_balances", %{
        provider_user_id: user.provider_user_id
      })

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
                  "amount" => 150_000 * btc.subunit_to_unit,
                  "minted_token" => %{
                    "name" => btc.name,
                    "object" => "minted_token",
                    "subunit_to_unit" => btc.subunit_to_unit,
                    "symbol" => btc.symbol,
                    "id" => btc.friendly_id,
                    "metadata" => %{},
                    "encrypted_metadata" => %{},
                    "created_at" => Date.to_iso8601(btc.inserted_at),
                    "updated_at" => Date.to_iso8601(btc.updated_at)
                  }
                },
                %{
                  "object" => "balance",
                  "amount" => 12_000 * omg.subunit_to_unit,
                  "minted_token" => %{
                    "name" => omg.name,
                    "object" => "minted_token",
                    "subunit_to_unit" => omg.subunit_to_unit,
                    "symbol" => omg.symbol,
                    "id" => omg.friendly_id,
                    "metadata" => %{},
                    "encrypted_metadata" => %{},
                    "created_at" => Date.to_iso8601(omg.inserted_at),
                    "updated_at" => Date.to_iso8601(omg.updated_at)
                  }
                }
              ]
            }
          ]
        }
      }
    end

    test "Get all user balances from an address" do
      account = Account.get_master_account()
      master_balance = Account.get_primary_balance(account)
      {:ok, user} = :user |> params_for() |> User.insert()
      user_balance   = User.get_primary_balance(user)
      {:ok, btc} = :minted_token |> params_for(symbol: "BTC") |> MintedToken.insert()
      {:ok, omg} = :minted_token |> params_for(symbol: "OMG") |> MintedToken.insert()

      mint!(btc)
      mint!(omg)

      transfer!(master_balance.address, user_balance.address, btc, 150_000 * btc.subunit_to_unit)
      transfer!(master_balance.address, user_balance.address, omg, 12_000 * omg.subunit_to_unit)

      response = provider_request("/user.list_balances", %{
        address: user_balance.address
      })

      assert response == %{
        "version" => "1",
        "success" => true,
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
                  "amount" => 150_000 * btc.subunit_to_unit,
                  "minted_token" => %{
                    "name" => btc.name,
                    "object" => "minted_token",
                    "subunit_to_unit" => btc.subunit_to_unit,
                    "symbol" => btc.symbol,
                    "id" => btc.friendly_id,
                    "metadata" => %{},
                    "encrypted_metadata" => %{},
                    "created_at" => Date.to_iso8601(btc.inserted_at),
                    "updated_at" => Date.to_iso8601(btc.updated_at)
                  }
                },
                %{
                  "object" => "balance",
                  "amount" => 12_000 * omg.subunit_to_unit,
                  "minted_token" => %{
                    "name" => omg.name,
                    "object" => "minted_token",
                    "subunit_to_unit" => omg.subunit_to_unit,
                    "symbol" => omg.symbol,
                    "id" => omg.friendly_id,
                    "metadata" => %{},
                    "encrypted_metadata" => %{},
                    "created_at" => Date.to_iso8601(omg.inserted_at),
                    "updated_at" => Date.to_iso8601(omg.updated_at)
                  }
                }
              ]
            }
          ]
        }
      }
    end

    test "Get all user balances with an invalid parameter should fail" do
      request_data = %{some_invalid_param: "some_invalid_value"}
      response     = provider_request("/user.list_balances", request_data)

      assert response == %{
        "version" => "1",
        "success" => false,
        "data" => %{
          "object" => "error",
          "code" => "client:invalid_parameter",
          "description" => "Invalid parameter provided",
          "messages" => nil
        }
      }
    end

    test "Get all user balances with a nil provider_user_id should fail" do
      request_data = %{provider_user_id: nil}
      response     = provider_request("/user.list_balances", request_data)

      assert response == %{
        "version" => "1",
        "success" => false,
        "data" => %{
          "object" => "error",
          "code" => "client:invalid_parameter",
          "description" => "Invalid parameter provided",
          "messages" => nil
        }
      }
    end

    test "Get all user balances with a nil address should fail" do
      request_data = %{address: nil}
      response     = provider_request("/user.list_balances", request_data)

      assert response == %{
        "version" => "1",
        "success" => false,
        "data" => %{
          "object" => "error",
          "code" => "client:invalid_parameter",
          "description" => "Invalid parameter provided",
          "messages" => nil
        }
      }
    end
  end
end
