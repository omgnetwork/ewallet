defmodule KuberaAPI.V1.SelfControllerTest do
  use KuberaAPI.ConnCase, async: true
  import Mock
  alias KuberaMQ.Balance
  alias KuberaDB.User

  describe "/me.get" do
    test "responds with user data" do
      response = client_request("/me.get")

      assert response["success"]
      assert response["data"]["username"] == @username
    end
  end

  describe "/me.get_settings" do
    test "responds with a list of minted_tokens" do
      response = client_request("/me.get_settings")

      assert response["success"]
      assert Map.has_key?(response["data"], "minted_tokens")
      assert is_list(response["data"]["minted_tokens"])
    end
  end

  def valid_balances_response do
    {:ok, %{
      "object" => "balance",
      "address" => "master",
      "amounts" => %{"BTC:123" => 9850, "OMG:123" => 1000}
    }}
  end

  describe "/me.list_balances" do
    test "responds with a list of balances" do
      with_mocks [
        {Balance, [], [all: fn _pid -> valid_balances_response() end]}
      ] do
        user     = get_test_user()
        btc      = insert(:minted_token, %{friendly_id: "BTC:123", symbol: "BTC"})
        omg      = insert(:minted_token, %{friendly_id: "OMG:123", symbol: "OMG"})
        response = client_request("/me.list_balances")

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
  end
end
