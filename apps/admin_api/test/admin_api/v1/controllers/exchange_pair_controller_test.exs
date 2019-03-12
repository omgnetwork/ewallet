# Copyright 2018-2019 OmiseGO Pte Ltd
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

defmodule AdminAPI.V1.ExchangePairControllerTest do
  use AdminAPI.ConnCase, async: true
  alias EWalletDB.{ExchangePair, Repo}
  alias ActivityLogger.System
  alias Utils.Helpers.DateFormatter

  describe "/exchange_pair.all" do
    test_with_auths "returns a list of exchange pairs and pagination data" do
      response = request("/exchange_pair.all")

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

    test_with_auths "returns a list of exchange pairs according to search_term, sort_by and sort_direction" do
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

      response = request("/exchange_pair.all", attrs)
      exchange_pairs = response["data"]["data"]

      assert response["success"]
      assert Enum.count(exchange_pairs) == 3
      assert Enum.at(exchange_pairs, 0)["id"] == "exg_aaaaa333333333333333333333"
      assert Enum.at(exchange_pairs, 1)["id"] == "exg_aaaaa222222222222222222222"
      assert Enum.at(exchange_pairs, 2)["id"] == "exg_aaaaa111111111111111111111"
    end

    test_supports_match_any("/exchange_pair.all", :exchange_pair, :id)
    test_supports_match_all("/exchange_pair.all", :exchange_pair, :id)
  end

  describe "/exchange_pair.get" do
    test_with_auths "returns an exchange pair by the given exchange pair's ID" do
      exchange_pairs = insert_list(3, :exchange_pair)

      # Pick the 2nd inserted exchange pairs
      target = Enum.at(exchange_pairs, 1)
      response = request("/exchange_pair.get", %{"id" => target.id})

      assert response["success"]
      assert response["data"]["object"] == "exchange_pair"
      assert response["data"]["id"] == target.id
    end

    test_with_auths "returns :invalid_parameter error when id is not given" do
      response = request("/exchange_pair.get", %{})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"
      assert response["data"]["description"] == "Invalid parameter provided. `id` is required."
    end

    test_with_auths "returns 'unauthorized' if the given ID was not found" do
      response = request("/exchange_pair.get", %{"id" => "exg_12345678901234567890123456"})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "unauthorized"
    end

    test_with_auths "returns 'unauthorized' if the given ID format is invalid" do
      response = request("/exchange_pair.get", %{"id" => "not_an_id"})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "unauthorized"
    end
  end

  describe "/exchange_pair.create" do
    def insert_params do
      %{
        from_token_id: insert(:token).id,
        to_token_id: insert(:token).id,
        rate: 2,
        sync_opposite: false,
        originator: %System{}
      }
    end

    def insert_params(overrides), do: Map.merge(insert_params(), overrides)

    test_with_auths "creates a new exchange pair and returns it in a list" do
      request_data = insert_params()
      response = request("/exchange_pair.create", request_data)

      assert response["success"] == true
      assert response["data"]["object"] == "list"

      pair = Enum.at(response["data"]["data"], 0)

      assert pair["object"] == "exchange_pair"
      assert pair["from_token_id"] == request_data.from_token_id
      assert pair["to_token_id"] == request_data.to_token_id
      assert pair["rate"] == 2.0
    end

    test_with_auths "creates a new exchange pair along with its opposite when given sync_opposite: true" do
      request_data = insert_params(%{sync_opposite: true})
      response = request("/exchange_pair.create", request_data)

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

    test_with_auths "returns client:invalid_parameter error if given an exchange rate of 0" do
      request_data = insert_params(%{rate: 0})
      response = request("/exchange_pair.create", request_data)

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"

      assert response["data"]["description"] ==
               "Invalid parameter provided. `rate` must be greater than 0."
    end

    test_with_auths "returns client:invalid_parameter error if given a negative exchange rate" do
      request_data = insert_params(%{rate: -1})
      response = request("/exchange_pair.create", request_data)

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"

      assert response["data"]["description"] ==
               "Invalid parameter provided. `rate` must be greater than 0."
    end

    test_with_auths "returns client:invalid_parameter error if rate is not provided" do
      request_data = insert_params(%{rate: nil})
      response = request("/exchange_pair.create", request_data)

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"

      assert response["data"]["description"] ==
               "Invalid parameter provided. `rate` can't be blank."
    end

    test_with_auths "returns client:invalid_parameter error if from_token_id is not provided" do
      request_data = insert_params(%{from_token_id: nil})
      response = request("/exchange_pair.create", request_data)

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"

      assert response["data"]["description"] ==
               "Invalid parameter provided. `from_token_id` can't be blank."
    end

    test_with_auths "returns client:invalid_parameter error if to_token_id is not provided" do
      request_data = insert_params(%{to_token_id: nil})
      response = request("/exchange_pair.create", request_data)

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"

      assert response["data"]["description"] ==
               "Invalid parameter provided. `to_token_id` can't be blank."
    end

    test_with_auths "returns client:invalid_parameter error if from_token_id and to_token_id are the same" do
      omg = insert(:token)

      request_data = insert_params(%{from_token_id: omg.id, to_token_id: omg.id})
      response = request("/exchange_pair.create", request_data)

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"

      assert response["data"]["description"] ==
               "Invalid parameter provided. `to_token_id` can't have the same value as `from_token_id`."
    end

    defp assert_create_logs(logs, originator, target) do
      assert Enum.count(logs) == 1

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "insert",
        originator: originator,
        target: target,
        changes: %{
          "from_token_uuid" => target.from_token.uuid,
          "rate" => target.rate,
          "to_token_uuid" => target.to_token.uuid
        },
        encrypted_changes: %{}
      )
    end

    test "generates an activity log for an admin request" do
      timestamp = DateTime.utc_now()
      request_data = insert_params()
      response = admin_user_request("/exchange_pair.create", request_data)

      assert response["success"] == true

      exchange_pair =
        ExchangePair
        |> get_last_inserted()
        |> Repo.preload([:from_token, :to_token])

      timestamp
      |> get_all_activity_logs_since()
      |> assert_create_logs(get_test_admin(), exchange_pair)
    end

    test "generates an activity log for a provider request" do
      timestamp = DateTime.utc_now()
      request_data = insert_params()
      response = provider_request("/exchange_pair.create", request_data)

      assert response["success"] == true

      exchange_pair =
        ExchangePair
        |> get_last_inserted()
        |> Repo.preload([:from_token, :to_token])

      timestamp
      |> get_all_activity_logs_since()
      |> assert_create_logs(get_test_key(), exchange_pair)
    end
  end

  describe "/exchange_pair.update" do
    test_with_auths "updates the given exchange pair" do
      exchange_pair = :exchange_pair |> insert() |> Repo.preload([:from_token, :to_token])

      assert exchange_pair.rate != 999.99

      # Prepare the update data while keeping only id the same
      request_data = %{
        id: exchange_pair.id,
        rate: 999.99
      }

      response = request("/exchange_pair.update", request_data)

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

    test_with_auths "updates the opposite pair when given sync_opposite: true" do
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

      response = request("/exchange_pair.update", request_data)

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

    test_with_auths "reverts and returns error if sync_opposite: true but opposite pair is not found" do
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

      response = request("/exchange_pair.update", request_data)

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "exchange:opposite_pair_not_found"

      assert response["data"]["description"] ==
               "The opposite exchange pair for the given tokens could not be found."
    end

    test_with_auths "returns a 'client:invalid_parameter' error if id is not provided" do
      response = request("/exchange_pair.update", %{rate: 999.99})

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"
      assert response["data"]["description"] == "Invalid parameter provided."
    end

    test_with_auths "returns a 'unauthorized' error if id is invalid" do
      response = request("/exchange_pair.update", %{id: "invalid_id"})

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "unauthorized"
    end

    test_with_auths "returns an error if given an exchange rate of 0" do
      pair = :exchange_pair |> insert() |> Repo.preload([:from_token, :to_token])
      response = request("/exchange_pair.update", %{id: pair.id, rate: 0})

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"

      assert response["data"]["description"] ==
               "Invalid parameter provided. `rate` must be greater than 0."
    end

    test_with_auths "returns an error if given a negative exchange rate" do
      pair = :exchange_pair |> insert() |> Repo.preload([:from_token, :to_token])
      response = request("/exchange_pair.update", %{id: pair.id, rate: -1})

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"

      assert response["data"]["description"] ==
               "Invalid parameter provided. `rate` must be greater than 0."
    end

    defp assert_update_logs(logs, originator, target) do
      assert Enum.count(logs) == 1

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "update",
        originator: originator,
        target: target,
        changes: %{
          "rate" => target.rate
        },
        encrypted_changes: %{}
      )
    end

    test "generates an activity log for an admin request" do
      exchange_pair = :exchange_pair |> insert() |> Repo.preload([:from_token, :to_token])
      timestamp = DateTime.utc_now()

      request_data = %{
        id: exchange_pair.id,
        rate: 999.99
      }

      response = admin_user_request("/exchange_pair.update", request_data)

      assert response["success"] == true

      exchange_pair = ExchangePair.get(exchange_pair.id)

      timestamp
      |> get_all_activity_logs_since()
      |> assert_update_logs(get_test_admin(), exchange_pair)
    end

    test "generates an activity log for a provider request" do
      exchange_pair = :exchange_pair |> insert() |> Repo.preload([:from_token, :to_token])
      timestamp = DateTime.utc_now()

      request_data = %{
        id: exchange_pair.id,
        rate: 999.99
      }

      response = provider_request("/exchange_pair.update", request_data)

      exchange_pair = ExchangePair.get(exchange_pair.id)

      assert response["success"] == true

      timestamp
      |> get_all_activity_logs_since()
      |> assert_update_logs(get_test_key(), exchange_pair)
    end
  end

  describe "/exchange_pair.delete" do
    test_with_auths "responds success with the deleted exchange pair" do
      exchange_pair = insert(:exchange_pair)
      response = request("/exchange_pair.delete", %{id: exchange_pair.id})

      assert response["success"] == true
      assert response["data"]["object"] == "list"
      assert Enum.count(response["data"]["data"]) == 1

      pair = Enum.at(response["data"]["data"], 0)
      assert pair["object"] == "exchange_pair"
      assert pair["deleted_at"] != nil
    end

    test_with_auths "deletes the opposite pair when sync_opposite: true" do
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

      response = request("/exchange_pair.delete", request_data)

      assert response["success"] == true
      assert response["data"]["object"] == "list"

      pair = Enum.at(response["data"]["data"], 0)
      assert pair["object"] == "exchange_pair"
      assert pair["deleted_at"] != nil

      pair = Enum.at(response["data"]["data"], 1)
      assert pair["object"] == "exchange_pair"
      assert pair["deleted_at"] != nil
    end

    test_with_auths "reverts and returns error if sync_opposite: true but opposite pair is not found" do
      pair = insert(:exchange_pair, rate: 2)

      # Prepare the update data while keeping only id the same
      request_data = %{
        id: pair.id,
        sync_opposite: true
      }

      response = request("/exchange_pair.delete", request_data)

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "exchange:opposite_pair_not_found"

      assert response["data"]["description"] ==
               "The opposite exchange pair for the given tokens could not be found."

      assert ExchangePair.get(pair.id) != nil
    end

    test_with_auths "responds with an error if the provided id is not found" do
      response = request("/exchange_pair.delete", %{id: "wrong_id"})

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "unauthorized"
    end

    test_with_auths "responds with an error if the user is not authorized to delete the exchange pair" do
      exchange_pair = insert(:exchange_pair)
      auth_token = insert(:auth_token, owner_app: "admin_api")
      key = insert(:key)

      attrs = %{id: exchange_pair.id}

      opts = [
        user_id: auth_token.user.id,
        auth_token: auth_token.token,
        access_key: key.access_key,
        secret_key: key.secret_key
      ]

      response = request("/exchange_pair.delete", attrs, opts)

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

    defp assert_delete_logs(logs, originator, target) do
      assert Enum.count(logs) == 1

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "update",
        originator: originator,
        target: target,
        changes: %{
          "deleted_at" => DateFormatter.to_iso8601(target.deleted_at)
        },
        encrypted_changes: %{}
      )
    end

    test "generates an activity log for an admin request" do
      timestamp = DateTime.utc_now()
      exchange_pair = insert(:exchange_pair)

      response = admin_user_request("/exchange_pair.delete", %{id: exchange_pair.id})

      assert response["success"] == true
      exchange_pair = Repo.get_by(ExchangePair, %{id: exchange_pair.id})

      timestamp
      |> get_all_activity_logs_since()
      |> assert_delete_logs(get_test_admin(), exchange_pair)
    end

    test "generates an activity log for a provider request" do
      timestamp = DateTime.utc_now()
      exchange_pair = insert(:exchange_pair)

      response = provider_request("/exchange_pair.delete", %{id: exchange_pair.id})

      assert response["success"] == true
      exchange_pair = Repo.get_by(ExchangePair, %{id: exchange_pair.id})

      timestamp
      |> get_all_activity_logs_since()
      |> assert_delete_logs(get_test_key(), exchange_pair)
    end
  end
end
