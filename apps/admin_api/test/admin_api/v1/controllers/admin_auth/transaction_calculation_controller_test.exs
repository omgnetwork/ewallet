defmodule AdminAPI.V1.AdminAuth.TransactionCalculationControllerTest do
  use AdminAPI.ConnCase, async: true

  # credo:disable-for-next-line
  setup do
    eth = insert(:token)
    omg = insert(:token)
    pair = insert(:exchange_pair, from_token: eth, to_token: omg, rate: 10)

    %{
      eth: eth,
      omg: omg,
      pair: pair
    }
  end

  describe "/transaction.calculate" do
    test "returns the calculation when all params are provided", context do
      response =
        admin_user_request("/transaction.calculate", %{
          "from_amount" => 100,
          "from_token_id" => context.eth.id,
          "to_amount" => 100 * context.pair.rate,
          "to_token_id" => context.omg.id
        })

      assert response["success"] == true
      assert response["data"]["object"] == "transaction_calculation"

      assert response["data"]["from_amount"] == 100
      assert response["data"]["from_token_id"] == context.eth.id
      assert response["data"]["to_amount"] == 100 * context.pair.rate
      assert response["data"]["to_token_id"] == context.omg.id
      assert response["data"]["calculated_at"] != nil

      assert response["data"]["exchange_pair"]["object"] == "exchange_pair"
      assert response["data"]["exchange_pair"]["id"] == context.pair.id
    end

    test "accepts integer strings", context do
      response =
        admin_user_request("/transaction.calculate", %{
          "from_amount" => "100",
          "from_token_id" => context.eth.id,
          "to_amount" => "1000",
          "to_token_id" => context.omg.id
        })

      assert response["success"] == true
      assert response["data"]["object"] == "transaction_calculation"

      assert response["data"]["from_amount"] == 100
      assert response["data"]["from_token_id"] == context.eth.id
      assert response["data"]["to_amount"] == 100 * context.pair.rate
      assert response["data"]["to_token_id"] == context.omg.id
    end

    test "returns the calculation when `from_amount` is left out", context do
      response =
        admin_user_request("/transaction.calculate", %{
          # "from_amount" => 200 / context.pair.rate,
          "from_token_id" => context.eth.id,
          "to_amount" => 200,
          "to_token_id" => context.omg.id
        })

      assert response["success"] == true
      assert response["data"]["object"] == "transaction_calculation"

      assert response["data"]["from_amount"] == 200 / context.pair.rate
      assert response["data"]["from_token_id"] == context.eth.id
      assert response["data"]["to_amount"] == 200
      assert response["data"]["to_token_id"] == context.omg.id
      assert response["data"]["calculated_at"] != nil

      assert response["data"]["exchange_pair"]["object"] == "exchange_pair"
      assert response["data"]["exchange_pair"]["id"] == context.pair.id
    end

    test "returns the calculation when `to_amount` is left out", context do
      response =
        admin_user_request("/transaction.calculate", %{
          "from_amount" => 300,
          "from_token_id" => context.eth.id,
          # "to_amount" => 300 * context.pair.rate,
          "to_token_id" => context.omg.id
        })

      assert response["success"] == true
      assert response["data"]["object"] == "transaction_calculation"

      assert response["data"]["from_amount"] == 300
      assert response["data"]["from_token_id"] == context.eth.id
      assert response["data"]["to_amount"] == 300 * context.pair.rate
      assert response["data"]["to_token_id"] == context.omg.id
      assert response["data"]["calculated_at"] != nil

      assert response["data"]["exchange_pair"]["object"] == "exchange_pair"
      assert response["data"]["exchange_pair"]["id"] == context.pair.id
    end

    test "returns an error when the amounts conflict with the available exchange pair", context do
      response =
        admin_user_request("/transaction.calculate", %{
          "from_amount" => 100,
          "from_token_id" => context.eth.id,
          "to_amount" => 999_999,
          "to_token_id" => context.omg.id
        })

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "exchange:invalid_rate"

      assert response["data"]["description"] ==
               "expected 'from_amount' to be 100 and 'to_amount' to be 1000, got 100 and 999999"
    end

    test "returns an error when `from_token_id` is missing", context do
      response =
        admin_user_request("/transaction.calculate", %{
          "from_amount" => 100,
          # "from_token_id" => context.eth.id,
          "to_amount" => 100 * context.pair.rate,
          "to_token_id" => context.omg.id
        })

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"
      assert response["data"]["description"] == "`from_token_id` is required"
    end

    test "returns an error when `to_token_id` is missing", context do
      response =
        admin_user_request("/transaction.calculate", %{
          "from_amount" => 100,
          "from_token_id" => context.eth.id,
          "to_amount" => 100 * context.pair.rate
          # "to_token_id" => context.omg.id
        })

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"
      assert response["data"]["description"] == "`to_token_id` is required"
    end

    test "returns an error when both `from_token_id` and `to_token_id` are missing", context do
      response =
        admin_user_request("/transaction.calculate", %{
          "from_amount" => 100,
          # "from_token_id" => context.eth.id,
          "to_amount" => 100 * context.pair.rate
          # "to_token_id" => context.omg.id
        })

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"

      assert response["data"]["description"] ==
               "both `from_token_id` and `to_token_id` are required"
    end

    test "returns an error when both `from_amount` and `to_amount` are missing", context do
      response =
        admin_user_request("/transaction.calculate", %{
          # "from_amount" => 100,
          "from_token_id" => context.eth.id,
          # "to_amount" => 100 * context.pair.rate
          "to_token_id" => context.omg.id
        })

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"
      assert response["data"]["description"] == "either `from_amount` or `to_amount` is required"
    end

    test "returns an error when the exchange pair does not exist", context do
      other_token = insert(:token)

      response =
        admin_user_request("/transaction.calculate", %{
          "from_amount" => 100,
          "from_token_id" => context.eth.id,
          "to_amount" => 100 * context.pair.rate,
          "to_token_id" => other_token.id
        })

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "exchange:pair_not_found"

      assert response["data"]["description"] ==
               "There is no exchange pair corresponding to the provided tokens."
    end
  end
end
