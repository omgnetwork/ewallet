defmodule EWalletAPI.V1.TransactionControllerTest do
  use EWalletAPI.ConnCase, async: true
  alias EWalletDB.User

  setup do
    user = get_test_user()
    balance = User.get_primary_balance(user)

    %{
      user:    user,
      from_1:  insert(:transfer, %{from_balance: balance, status: "confirmed"}),
      from_2:  insert(:transfer, %{from_balance: balance, status: "confirmed"}),
      to_1:    insert(:transfer, %{to_balance:   balance, status: "confirmed"}),
      to_2:    insert(:transfer, %{to_balance:   balance, status: "confirmed"}),
      other_1: insert(:transfer, %{status: "confirmed"}),
      other_2: insert(:transfer, %{status: "pending"}),
      other_3: insert(:transfer, %{status: "confirmed"})
    }
  end

  describe "/transactions.all" do
    test "returns all the transactions", meta do
      response = provider_request("/transaction.all", %{})
      assert response["data"]["data"] |> length() == 7
      assert Enum.map(response["data"]["data"], fn t ->
        t["id"]
      end) == [
        meta.from_1.id,
        meta.from_2.id,
        meta.to_1.id,
        meta.to_2.id,
        meta.other_1.id,
        meta.other_2.id,
        meta.other_3.id
      ]
    end

    test "returns all the transactions for a specific address", meta do
      response = provider_request("/transaction.all", %{
        "search_terms" => %{
          "from" => meta.from_1.from,
          "to"   => meta.from_2.to
        }
      })
      assert response["data"]["data"] |> length() == 2
      assert Enum.map(response["data"]["data"], fn t ->
        t["id"]
      end) == [
        meta.from_1.id,
        meta.from_2.id
      ]
    end

    test "returns all transactions filtered", meta do
      response = provider_request("/transaction.all", %{"search_term" => "pending"})
      assert response["data"]["data"] |> length() == 1
      transaction = Enum.at(response["data"]["data"], 0)
      assert transaction["id"] == meta.other_2.id
    end

    test "returns all transactions sorted and paginated" do
      response = provider_request("/transaction.all", %{
        "sort_by" => "created_at",
        "sort_dir" => "asc",
        "per_page" => 2,
        "page" => 1
      })
      assert response["data"]["data"] |> length() == 2
      transaction_1 = Enum.at(response["data"]["data"], 0)
      transaction_2 = Enum.at(response["data"]["data"], 1)
      assert transaction_2["created_at"] > transaction_1["created_at"]
    end
  end

  describe "/user.list_transactions" do
    test "returns all the transactions", meta do
      response = provider_request("/user.list_transactions", %{
        "provider_user_id" => meta.user.provider_user_id
      })
      assert response["data"]["data"] |> length() == 4
      assert Enum.map(response["data"]["data"], fn t ->
        t["id"]
      end) == [
        meta.from_1.id,
        meta.from_2.id,
        meta.to_1.id,
        meta.to_2.id,
      ]
    end

    test "returns all the transactions that belong to a specific provider_user_id", meta do
      response = provider_request("/user.list_transactions", %{
        "provider_user_id" => meta.user.provider_user_id
      })
      assert response["data"]["data"] |> length() == 4
      assert Enum.map(response["data"]["data"], fn t ->
        t["id"]
      end) == [
        meta.from_1.id,
        meta.from_2.id,
        meta.to_1.id,
        meta.to_2.id
      ]
    end

    test "returns the user's transactions even when different search terms are provided", meta do
      response = provider_request("/user.list_transactions", %{
        "provider_user_id" => meta.user.provider_user_id,
        "sort_by" => "created_at",
        "sort_dir" => "desc",
        "search_terms" => %{
          "from" => meta.from_1.from,
          "to"   => meta.from_2.to
        }
      })
      assert response["data"]["data"] |> length() == 4
      assert Enum.map(response["data"]["data"], fn t ->
        t["id"]
      end) == [
        meta.to_2.id,
        meta.to_1.id,
        meta.from_2.id,
        meta.from_1.id
      ]
    end

    test "returns all transactions filtered", meta do
      response = provider_request("/user.list_transactions", %{
        "provider_user_id" => meta.user.provider_user_id,
        "search_term" => "pending"
      })
      assert response["data"]["data"] |> length() == 1
      transaction = Enum.at(response["data"]["data"], 0)
      assert transaction["id"] == meta.other_2.id
    end

    test "returns all transactions sorted and paginated", meta do
      response = provider_request("/user.list_transactions", %{
        "provider_user_id" => meta.user.provider_user_id,
        "sort_by" => "created_at",
        "sort_dir" => "asc",
        "per_page" => 2,
        "page" => 1
      })
      assert response["data"]["data"] |> length() == 2
      transaction_1 = Enum.at(response["data"]["data"], 0)
      transaction_2 = Enum.at(response["data"]["data"], 1)
      assert transaction_2["created_at"] > transaction_1["created_at"]
    end
  end

  describe "/me.list_transactions" do
    test "returns all the transactions for the current user", meta do
      response = client_request("/me.list_transactions", %{})
      assert response["data"]["data"] |> length() == 4
      assert Enum.map(response["data"]["data"], fn t ->
        t["id"]
      end) == [
        meta.from_1.id,
        meta.from_2.id,
        meta.to_1.id,
        meta.to_2.id
      ]
    end

    test "returns all transactions for the current user sorted", meta do
      response = client_request("/me.list_transactions", %{
        "sort_by"  => "created_at",
        "sort_dir" => "desc"
      })

      assert Enum.map(response["data"]["data"], fn t ->
        t["id"]
      end) == [
        meta.to_2.id,
        meta.to_1.id,
        meta.from_2.id,
        meta.from_1.id
      ]
    end

    test "returns all transactions for the current user filtered", meta do
      response = client_request("/me.list_transactions", %{
        "search_term" => "pending"
      })

      assert Enum.map(response["data"]["data"], fn t ->
        t["id"]
      end) == [
        meta.other_2.id
      ]
    end

    test "returns all transactions for the current user paginated", meta do
      response = client_request("/me.list_transactions", %{
        "page"  => 2,
        "per_page" => 1,
        "sort_by"  => "created_at",
        "sort_dir" => "desc"
      })

      assert Enum.map(response["data"]["data"], fn t ->
        t["id"]
      end) == [
        meta.to_1.id
      ]
    end
  end
end
