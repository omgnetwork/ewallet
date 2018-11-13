defmodule AdminAPI.V1.ProviderAuth.ExchangePairControllerTest do
  use AdminAPI.ConnCase, async: true
  alias EWalletDB.{ExchangePair, Repo}

  describe "/exchange_pair.all" do
    test "returns a list of exchange pairs and pagination data" do
      response = provider_request("/exchange_pair.all")

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
      insert(:exchange_pair, %{id: "exg_aaaaa222222222222222222222"})
      insert(:exchange_pair, %{id: "exg_aaaaa333333333333333333333"})
      insert(:exchange_pair, %{id: "exg_aaaaa111111111111111111111"})
      insert(:exchange_pair, %{id: "exg_fffff000000000000000000000"})

      attrs = %{
        # Search is case-insensitive
        "search_term" => "exg_AAAAA",
        "sort_by" => "id",
        "sort_dir" => "desc"
      }

      response = provider_request("/exchange_pair.all", attrs)
      exchange_pairs = response["data"]["data"]

      assert response["success"]
      assert Enum.count(exchange_pairs) == 3
      assert Enum.at(exchange_pairs, 0)["id"] == "exg_aaaaa333333333333333333333"
      assert Enum.at(exchange_pairs, 1)["id"] == "exg_aaaaa222222222222222222222"
      assert Enum.at(exchange_pairs, 2)["id"] == "exg_aaaaa111111111111111111111"
    end
  end

  describe "/exchange_pair.get" do
    test "returns an exchange pair by the given exchange pair's ID" do
      exchange_pairs = insert_list(3, :exchange_pair)

      # Pick the 2nd inserted exchange pairs
      target = Enum.at(exchange_pairs, 1)
      response = provider_request("/exchange_pair.get", %{"id" => target.id})

      assert response["success"]
      assert response["data"]["object"] == "exchange_pair"
      assert response["data"]["id"] == target.id
    end

    test "returns 'exchange:pair_id_not_found' if the given ID was not found" do
      response =
        provider_request("/exchange_pair.get", %{"id" => "exg_12345678901234567890123456"})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "exchange:pair_id_not_found"

      assert response["data"]["description"] ==
               "There is no exchange pair corresponding to the provided id."
    end

    test "returns 'exchange:id_not_found' if the given ID format is invalid" do
      response = provider_request("/exchange_pair.get", %{"id" => "not_an_id"})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "exchange:pair_id_not_found"

      assert response["data"]["description"] ==
               "There is no exchange pair corresponding to the provided id."
    end
  end

  describe "/exchange_pair.create" do
    def insert_params do
      %{
        from_token_id: insert(:token).id,
        to_token_id: insert(:token).id,
        rate: 2,
        sync_opposite: false
      }
    end

    def insert_params(overrides), do: Map.merge(insert_params(), overrides)

    test "creates a new exchange pair and returns it in a list" do
      request_data = insert_params()
      response = provider_request("/exchange_pair.create", request_data)

      assert response["success"] == true
      assert response["data"]["object"] == "list"

      pair = Enum.at(response["data"]["data"], 0)

      assert pair["object"] == "exchange_pair"
      assert pair["from_token_id"] == request_data.from_token_id
      assert pair["to_token_id"] == request_data.to_token_id
      assert pair["rate"] == 2.0
    end

    test "creates a new exchange pair along with its opposite when given sync_opposite: true" do
      request_data = insert_params(%{sync_opposite: true})
      response = provider_request("/exchange_pair.create", request_data)

      assert response["success"] == true
      assert response["data"]["object"] == "list"

      pair = Enum.at(response["data"]["data"], 0)

      assert pair["object"] == "exchange_pair"
      assert pair["from_token_id"] == request_data.from_token_id
      assert pair["to_token_id"] == request_data.to_token_id
      assert pair["rate"] == 2.0

      opposite = Enum.at(response["data"]["data"], 1)

      assert opposite["object"] == "exchange_pair"
      assert opposite["from_token_id"] == request_data.to_token_id
      assert opposite["to_token_id"] == request_data.from_token_id
      assert opposite["rate"] == 1 / 2.0
    end

    test "returns client:invalid_parameter error if given an exchange rate of 0" do
      request_data = params_for(:exchange_pair, rate: 0)
      response = provider_request("/exchange_pair.create", request_data)

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"

      assert response["data"]["description"] ==
               "Invalid parameter provided. `rate` must be greater than 0."
    end

    test "returns client:invalid_parameter error if given a negative exchange rate" do
      request_data = params_for(:exchange_pair, rate: -1)
      response = provider_request("/exchange_pair.create", request_data)

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"

      assert response["data"]["description"] ==
               "Invalid parameter provided. `rate` must be greater than 0."
    end

    test "returns client:invalid_parameter error if a required parameter is not provided" do
      request_data = params_for(:exchange_pair, rate: nil)
      response = provider_request("/exchange_pair.create", request_data)

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"

      assert response["data"]["description"] ==
               "Invalid parameter provided. `rate` can't be blank."
    end

    test "returns client:invalid_parameter error if from_token_id is not provided" do
      request_data = insert_params(%{from_token_id: nil})
      response = provider_request("/exchange_pair.create", request_data)

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"

      assert response["data"]["description"] ==
               "Invalid parameter provided. `from_token_id` can't be blank."
    end

    test "returns client:invalid_parameter error if to_token_id is not provided" do
      request_data = insert_params(%{to_token_id: nil})
      response = provider_request("/exchange_pair.create", request_data)

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"

      assert response["data"]["description"] ==
               "Invalid parameter provided. `to_token_id` can't be blank."
    end
  end

  describe "/exchange_pair.update" do
    test "updates the given exchange pair" do
      exchange_pair = :exchange_pair |> insert() |> Repo.preload([:from_token, :to_token])

      assert exchange_pair.rate != 999.99

      # Prepare the update data while keeping only id the same
      request_data = %{
        id: exchange_pair.id,
        rate: 999.99
      }

      response = provider_request("/exchange_pair.update", request_data)

      assert response["success"] == true
      assert response["data"]["object"] == "list"
      assert Enum.count(response["data"]["data"]) == 1

      pair = Enum.at(response["data"]["data"], 0)

      assert pair["object"] == "exchange_pair"
      assert pair["id"] == exchange_pair.id
      assert pair["from_token_id"] == exchange_pair.from_token.id
      assert pair["to_token_id"] == exchange_pair.to_token.id
      assert pair["rate"] == 999.99
    end

    test "updates the opposite pair when given sync_opposite: true" do
      exchange_pair =
        :exchange_pair
        |> insert(rate: 2)
        |> Repo.preload([:from_token, :to_token])

      opposite_pair =
        :exchange_pair
        |> insert(
          rate: 99,
          from_token: exchange_pair.to_token,
          to_token: exchange_pair.from_token
        )
        |> Repo.preload([:from_token, :to_token])

      # Prepare the update data while keeping only id the same
      request_data = %{
        id: exchange_pair.id,
        rate: 1000,
        sync_opposite: true
      }

      response = provider_request("/exchange_pair.update", request_data)

      assert response["success"] == true
      assert response["data"]["object"] == "list"
      assert Enum.count(response["data"]["data"]) == 2

      pair = Enum.at(response["data"]["data"], 0)
      assert pair["id"] == exchange_pair.id
      assert pair["rate"] == 1000

      pair = Enum.at(response["data"]["data"], 1)
      assert pair["id"] == opposite_pair.id
      assert pair["rate"] == 1 / 1000
    end

    test "reverts and returns error if sync_opposite: true but opposite pair is not found" do
      exchange_pair =
        :exchange_pair
        |> insert(rate: 2)
        |> Repo.preload([:from_token, :to_token])

      assert exchange_pair.rate == 2

      # Prepare the update data while keeping only id the same
      request_data = %{
        id: exchange_pair.id,
        rate: 1000,
        sync_opposite: true
      }

      response = provider_request("/exchange_pair.update", request_data)

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "exchange:opposite_pair_not_found"

      assert response["data"]["description"] ==
               "The opposite exchange pair for the given tokens could not be found."
    end

    test "returns a 'client:invalid_parameter' error if id is not provided" do
      response = provider_request("/exchange_pair.update", %{rate: 999.99})

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"
      assert response["data"]["description"] == "Invalid parameter provided."
    end

    test "returns a 'user:unauthorized' error if id is invalid" do
      response = provider_request("/exchange_pair.update", %{id: "invalid_id"})

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "exchange:pair_id_not_found"

      assert response["data"]["description"] ==
               "There is no exchange pair corresponding to the provided id."
    end

    test "returns an error if given an exchange rate of 0" do
      pair = :exchange_pair |> insert() |> Repo.preload([:from_token, :to_token])
      response = provider_request("/exchange_pair.update", %{id: pair.id, rate: 0})

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"

      assert response["data"]["description"] ==
               "Invalid parameter provided. `rate` must be greater than 0."
    end

    test "returns an error if given a negative exchange rate" do
      pair = :exchange_pair |> insert() |> Repo.preload([:from_token, :to_token])
      response = provider_request("/exchange_pair.update", %{id: pair.id, rate: -1})

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"

      assert response["data"]["description"] ==
               "Invalid parameter provided. `rate` must be greater than 0."
    end
  end

  describe "/exchange_pair.delete" do
    test "responds success with the deleted exchange pair" do
      exchange_pair = insert(:exchange_pair)
      response = provider_request("/exchange_pair.delete", %{id: exchange_pair.id})

      assert response["success"] == true
      assert response["data"]["object"] == "list"
      assert Enum.count(response["data"]["data"]) == 1

      pair = Enum.at(response["data"]["data"], 0)
      assert pair["object"] == "exchange_pair"
      assert pair["deleted_at"] != nil
    end

    test "deletes the opposite pair when sync_opposite: true" do
      exchange_pair = insert(:exchange_pair, rate: 2)

      _opposite =
        insert(
          :exchange_pair,
          from_token: exchange_pair.to_token,
          to_token: exchange_pair.from_token
        )

      # Prepare the deletion data while keeping only id the same
      request_data = %{
        id: exchange_pair.id,
        sync_opposite: true
      }

      response = provider_request("/exchange_pair.delete", request_data)

      assert response["success"] == true
      assert response["data"]["object"] == "list"

      pair = Enum.at(response["data"]["data"], 0)
      assert pair["object"] == "exchange_pair"
      assert pair["deleted_at"] != nil

      pair = Enum.at(response["data"]["data"], 1)
      assert pair["object"] == "exchange_pair"
      assert pair["deleted_at"] != nil
    end

    test "reverts and returns error if sync_opposite: true but opposite pair is not found" do
      pair = insert(:exchange_pair, rate: 2)

      # Prepare the update data while keeping only id the same
      request_data = %{
        id: pair.id,
        sync_opposite: true
      }

      response = provider_request("/exchange_pair.delete", request_data)

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "exchange:opposite_pair_not_found"

      assert response["data"]["description"] ==
               "The opposite exchange pair for the given tokens could not be found."

      assert ExchangePair.get(pair.id) != nil
    end

    test "responds with an error if the provided id is not found" do
      response = provider_request("/exchange_pair.delete", %{id: "wrong_id"})

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "exchange:pair_id_not_found"

      assert response["data"]["description"] ==
               "There is no exchange pair corresponding to the provided id."
    end

    test "responds with an error if the user is not authorized to delete the exchange pair" do
      exchange_pair = insert(:exchange_pair)
      key = insert(:key)

      attrs = %{id: exchange_pair.id}
      opts = [access_key: key.access_key, secret_key: key.secret_key]
      response = provider_request("/exchange_pair.delete", attrs, opts)

      assert response ==
               %{
                 "version" => "1",
                 "success" => false,
                 "data" => %{
                   "code" => "unauthorized",
                   "description" => "You are not allowed to perform the requested operation.",
                   "messages" => nil,
                   "object" => "error"
                 }
               }
    end
  end
end
