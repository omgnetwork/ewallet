defmodule AdminAPI.V1.AdminAuth.ExchangePairControllerTest do
  use AdminAPI.ConnCase, async: true

  describe "/exchange_pair.all" do
    test "returns a list of exchange pairs and pagination data" do
      response = admin_user_request("/exchange_pair.all")

      # Asserts return data
      assert response["success"]
      assert response["data"]["object"] == "list"
      assert is_list(response["data"]["data"])

      # Asserts pagination data
      pagination = response["data"]["pagination"]
      assert is_integer(pagination["per_page"])
      assert is_integer(pagination["current_page"])
      assert is_boolean(pagination["is_last_page"])
      assert is_boolean(pagination["is_first_page"])
    end

    test "returns a list of exchange pairs according to search_term, sort_by and sort_direction" do
      insert(:exchange_pair, %{name: "Matched 2"})
      insert(:exchange_pair, %{name: "Matched 3"})
      insert(:exchange_pair, %{name: "Matched 1"})
      insert(:exchange_pair, %{name: "Missed 1"})

      attrs = %{
        # Search is case-insensitive
        "search_term" => "MaTcHed",
        "sort_by" => "name",
        "sort_dir" => "desc"
      }

      response = admin_user_request("/exchange_pair.all", attrs)
      exchange_pairs = response["data"]["data"]

      assert response["success"]
      assert Enum.count(exchange_pairs) == 3
      assert Enum.at(exchange_pairs, 0)["name"] == "Matched 3"
      assert Enum.at(exchange_pairs, 1)["name"] == "Matched 2"
      assert Enum.at(exchange_pairs, 2)["name"] == "Matched 1"
    end
  end

  describe "/exchange_pair.get" do
    test "returns an exchange pair by the given exchange pair's ID" do
      exchange_pairs = insert_list(3, :exchange_pair)

      # Pick the 2nd inserted exchange pairs
      target = Enum.at(exchange_pairs, 1)
      response = admin_user_request("/exchange_pair.get", %{"id" => target.id})

      assert response["success"]
      assert response["data"]["object"] == "exchange_pair"
      assert response["data"]["name"] == target.name
    end

    test "returns 'exchange:pair_id_not_found' if the given ID was not found" do
      response = admin_user_request("/exchange_pair.get", %{"id" => "exg_12345678901234567890123456"})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "exchange:pair_id_not_found"

      assert response["data"]["description"] ==
               "There is no exchange pair corresponding to the provided id"
    end

    test "returns 'exchange:id_not_found' if the given ID format is invalid" do
      response = admin_user_request("/exchange_pair.get", %{"id" => "not_an_id"})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "exchange:pair_id_not_found"

      assert response["data"]["description"] ==
               "There is no exchange pair corresponding to the provided id"
    end
  end

  describe "/exchange_pair.create" do
    test "creates a new exchange pair and returns it" do
      request_data =
        %{
          name: "Test exchange pair",
          from_token_id: insert(:token).id,
          to_token_id: insert(:token).id,
          rate: 2.00,
          reversible: true
        }

      response = admin_user_request("/exchange_pair.create", request_data)

      assert response["success"] == true
      assert response["data"]["object"] == "exchange_pair"
      assert response["data"]["name"] == request_data.name
      assert response["data"]["from_token_id"] == request_data.from_token_id
      assert response["data"]["to_token_id"] == request_data.to_token_id
      assert response["data"]["rate"] == 2.00
      assert response["data"]["reversible"] == true
    end

    test "returns an error if a required parameter is not provided" do
      request_data = params_for(:exchange_pair, rate: nil)
      response = admin_user_request("/exchange_pair.create", request_data)

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"
    end
  end

  describe "/exchange_pair.update" do
    test "updates the given exchange pair" do
      exchange_pair = insert(:exchange_pair)

      assert exchange_pair.name != "updated name"
      assert exchange_pair.rate != 999.99

      # Prepare the update data while keeping only id the same
      request_data =
        params_for(:exchange_pair, %{
          id: exchange_pair.id,
          name: "updated name",
          rate: 999.99
        })

      response = provider_request("/exchange_pair.update", request_data)

      assert response["success"] == true
      assert response["data"]["object"] == "exchange_pair"
      assert response["data"]["name"] == "updated name"
      assert response["data"]["rate"] == 999.99
    end

    test "returns a 'client:invalid_parameter' error if id is not provided" do
      request_data = params_for(:exchange_pair, %{id: nil})
      response = admin_user_request("/exchange_pair.update", request_data)

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"
      assert response["data"]["description"] == "Invalid parameter provided"
    end

    test "returns a 'user:unauthorized' error if id is invalid" do
      request_data = params_for(:exchange_pair, %{id: "invalid_format"})
      response = admin_user_request("/exchange_pair.update", request_data)

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "exchange:pair_id_not_found"

      assert response["data"]["description"] ==
               "There is no exchange pair corresponding to the provided id"
    end
  end

  describe "/exchange_pair.delete" do
    test "responds success with the deleted exchange pair" do
      exchange_pair = insert(:exchange_pair)
      response = admin_user_request("/exchange_pair.delete", %{id: exchange_pair.id})

      assert response["success"] == true
      assert response["data"]["object"] == "exchange_pair"
      assert response["data"]["id"] == exchange_pair.id
    end

    test "responds with an error if the provided id is not found" do
      response = admin_user_request("/exchange_pair.delete", %{id: "wrong_id"})

      assert response ==
               %{
                 "version" => "1",
                 "success" => false,
                 "data" => %{
                   "code" => "exchange:pair_id_not_found",
                   "description" => "There is no exchange pair corresponding to the provided id",
                   "messages" => nil,
                   "object" => "error"
                 }
               }
    end
  end
end
