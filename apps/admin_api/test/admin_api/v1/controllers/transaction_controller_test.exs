defmodule AdminAPI.V1.TransactionControllerTest do
  use AdminAPI.ConnCase, async: true

  describe "/transaction.all" do
    test "returns a list of transactions and pagination data" do
      response = user_request("/transaction.all")

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

    test "returns a list of transactions according to search_term, sort_by and sort_direction" do
      wallet1 = insert(:wallet, address: "ABC1")
      wallet2 = insert(:wallet, address: "ABC3")
      wallet3 = insert(:wallet, address: "ABC2")
      wallet4 = insert(:wallet, address: "XYZ1")

      insert(:transfer, %{from_wallet: wallet1})
      insert(:transfer, %{from_wallet: wallet2})
      insert(:transfer, %{from_wallet: wallet3})
      insert(:transfer, %{from_wallet: wallet4})

      attrs = %{
        # Search is case-insensitive
        "search_term" => "aBc",
        "sort_by" => "from",
        "sort_dir" => "desc"
      }

      response = user_request("/transaction.all", attrs)
      transactions = response["data"]["data"]

      assert response["success"]
      assert Enum.count(transactions) == 3
      assert Enum.at(transactions, 0)["from"]["address"] == "ABC3"
      assert Enum.at(transactions, 1)["from"]["address"] == "ABC2"
      assert Enum.at(transactions, 2)["from"]["address"] == "ABC1"
    end
  end

  describe "/transaction.get" do
    test "returns an transaction by the given transaction's ID" do
      transactions = insert_list(3, :transfer)
      # Pick the 2nd inserted transaction
      target = Enum.at(transactions, 1)
      response = user_request("/transaction.get", %{"id" => target.id})

      assert response["success"]
      assert response["data"]["object"] == "transaction"
      assert response["data"]["id"] == target.id
    end

    test "returns 'transaction:id_not_found' if the given ID was not found" do
      response = user_request("/transaction.get", %{"id" => "tfr_12345678901234567890123456"})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "transaction:id_not_found"

      assert response["data"]["description"] ==
               "There is no transaction corresponding to the provided id"
    end

    test "returns 'transaction:id_not_found' if the given ID format is invalid" do
      response = user_request("/transaction.get", %{"id" => "not_valid_id"})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "transaction:id_not_found"

      assert response["data"]["description"] ==
               "There is no transaction corresponding to the provided id"
    end
  end
end
