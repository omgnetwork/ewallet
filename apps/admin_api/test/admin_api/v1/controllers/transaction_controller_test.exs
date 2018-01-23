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
      assert is_integer pagination["per_page"]
      assert is_integer pagination["current_page"]
      assert is_boolean pagination["is_last_page"]
      assert is_boolean pagination["is_first_page"]
    end

    test "returns a list of transactions according to search_term, sort_by and sort_direction" do
      balance1 = insert(:balance, address: "ABC1")
      balance2 = insert(:balance, address: "ABC3")
      balance3 = insert(:balance, address: "ABC2")
      balance4 = insert(:balance, address: "XYZ1")

      insert(:transfer, %{from_balance: balance1})
      insert(:transfer, %{from_balance: balance2})
      insert(:transfer, %{from_balance: balance3})
      insert(:transfer, %{from_balance: balance4})

      attrs = %{
        "search_term" => "aBc", # Search is case-insensitive
        "sort_by"     => "from",
        "sort_dir"    => "desc"
      }

      response = user_request("/transaction.all", attrs)
      transactions = response["data"]["data"]

      assert response["success"]
      assert Enum.count(transactions) == 3
      assert Enum.at(transactions, 0)["from"] == "ABC3"
      assert Enum.at(transactions, 1)["from"] == "ABC2"
      assert Enum.at(transactions, 2)["from"] == "ABC1"
    end
  end

  describe "/transaction.get" do
    test "returns an transaction by the given transaction's ID" do
      transactions    = insert_list(3, :transfer)
      target   = Enum.at(transactions, 1) # Pick the 2nd inserted transaction
      response = user_request("/transaction.get", %{"id" => target.id})

      assert response["success"]
      assert response["data"]["object"] == "transaction"
      assert response["data"]["id"] == target.id
    end

    test "returns 'transaction:id_not_found' if the given ID was not found" do
      response  = user_request("/transaction.get", %{"id" => "00000000-0000-0000-0000-000000000000"})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "transaction:id_not_found"
      assert response["data"]["description"] == "There is no transaction corresponding to the provided id"
    end

    test "returns 'client:invalid_parameter' if the given ID is not UUID" do
      response  = user_request("/transaction.get", %{"id" => "not_uuid"})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"
      assert response["data"]["description"] == "Transaction ID must be a UUID"
    end
  end
end
