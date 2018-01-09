defmodule KuberaAPI.V1.BalanceControllerTest do
  use KuberaAPI.ConnCase, async: true
  import Mock
  alias KuberaDB.{User, MintedToken}
  alias KuberaMQ.Publishers.Balance

  def valid_balances_response do
    {:ok, %{
      "object" => "balance",
      "address" => "master",
      "amounts" => %{"BTC:123" => 9850, "OMG:123" => 1000}
    }}
  end

  describe "/all" do
    test "Get all user balances from its provider_user_id" do
      with_mocks [
        {Balance, [], [all: fn _pid -> valid_balances_response() end]}
        ] do
          {:ok, user} = :user |> params_for() |> User.insert()
          {:ok, btc} =
            :minted_token |> params_for(friendly_id: "BTC:123", symbol: "BTC") |> MintedToken.insert()
          {:ok, omg} =
            :minted_token |> params_for(friendly_id: "OMG:123", symbol: "OMG") |> MintedToken.insert()

          request_data = %{provider_user_id: user.provider_user_id}
          response     = provider_request("/user.list_balances", request_data)

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
                        "name" => btc.name,
                        "object" => "minted_token",
                        "subunit_to_unit" => btc.subunit_to_unit,
                        "symbol" => btc.symbol,
                        "id" => btc.friendly_id,
                      }
                    },
                    %{
                      "object" => "balance",
                      "amount" => 1000,
                      "minted_token" => %{
                        "name" => omg.name,
                        "object" => "minted_token",
                        "subunit_to_unit" => omg.subunit_to_unit,
                        "symbol" => omg.symbol,
                        "id" => omg.friendly_id,
                      }
                    }
                  ]
                }
              ]
            }
          }
      end
    end

    test "Get all user balances from an address" do
      with_mocks [
        {Balance, [], [all: fn _pid -> valid_balances_response() end]}
        ] do
          {:ok, user} = :user |> params_for() |> User.insert()
          {:ok, btc} =
            :minted_token |> params_for(friendly_id: "BTC:123", symbol: "BTC") |> MintedToken.insert()
          {:ok, omg} =
            :minted_token |> params_for(friendly_id: "OMG:123", symbol: "OMG") |> MintedToken.insert()

          address      = User.get_primary_balance(user).address
          request_data = %{address: address}
          response     = provider_request("/user.list_balances", request_data)

          assert response == %{
            "version" => "1",
            "success" => true,
            "data" => %{
              "object" => "list",
              "data" => [
                %{
                  "object" => "address",
                  "address" => address,
                  "balances" => [
                    %{
                      "object" => "balance",
                      "amount" => 9850,
                      "minted_token" => %{
                        "name" => btc.name,
                        "object" => "minted_token",
                        "subunit_to_unit" => btc.subunit_to_unit,
                        "symbol" => btc.symbol,
                        "id" => btc.friendly_id
                      }
                    },
                    %{
                      "object" => "balance",
                      "amount" => 1000,
                      "minted_token" => %{
                        "name" => omg.name,
                        "object" => "minted_token",
                        "subunit_to_unit" => omg.subunit_to_unit,
                        "symbol" => omg.symbol,
                        "id" => omg.friendly_id
                      }
                    }
                  ]
                }
              ]
            }
          }
      end
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
