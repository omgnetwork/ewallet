# Copyright 2018 OmiseGO Pte Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule AdminAPI.V1.AdminAuth.TransactionCalculationControllerTest do
  use AdminAPI.ConnCase, async: true

  # credo:disable-for-next-line
  def setup do
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
    test_with_auths "returns the calculation when all params are provided" do
      context = setup()
      response =
        request("/transaction.calculate", %{
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

      assert response["data"]["exchange_pair"]["from_token"]["id"] == context.eth.id
      assert response["data"]["exchange_pair"]["to_token"]["id"] == context.omg.id
    end

    test_with_auths "accepts integer strings" do
      context = setup()
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

    test_with_auths "returns the calculation when `from_amount` is left out" do
      context = setup()
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

    test_with_auths "returns the calculation when `to_amount` is left out" do
      context = setup()
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

    test_with_auths "returns an error when the amounts conflict with the available exchange pair" do
      context = setup()
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

    test_with_auths "returns an error when `from_token_id` is missing" do
      context = setup()
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

    test_with_auths "returns an error when `to_token_id` is missing" do
      context = setup()
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

    test_with_auths "returns an error when both `from_token_id` and `to_token_id` are missing" do
      context = setup()
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

    test_with_auths "returns an error when both `from_amount` and `to_amount` are missing" do
      context = setup()
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

    test_with_auths "returns an error when the exchange pair does not exist" do
      context = setup()
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
