defmodule EWalletAPI.V1.TransactionControllerTest do
  use EWalletAPI.ConnCase, async: false
  alias EWalletDB.User

  setup do
    user = get_test_user()
    balance_1 = User.get_primary_balance(user)
    balance_2 = insert(:balance)
    balance_3 = insert(:balance)
    balance_4 = insert(:balance, user: user, identifier: "secondary")

    %{
      user:       user,
      balance_1:  balance_1,
      balance_2:  balance_2,
      balance_3:  balance_3,
      balance_4:  balance_4,
      transfer_1: insert(:transfer, %{
        from_balance: balance_1, to_balance: balance_2, status: "confirmed"
      }),
      transfer_2: insert(:transfer, %{
        from_balance: balance_2, to_balance: balance_1, status: "confirmed"
      }),
      transfer_3: insert(:transfer, %{
        from_balance: balance_1, to_balance: balance_3, status: "confirmed"
      }),
      transfer_4: insert(:transfer, %{
        from_balance: balance_1, to_balance: balance_2, status: "pending"
      }),
      transfer_5: insert(:transfer, %{status: "confirmed"}),
      transfer_6: insert(:transfer, %{status: "pending"}),
      transfer_7: insert(:transfer, %{
        from_balance: balance_4, to_balance: balance_2, status: "confirmed"
      }),
      transfer_8: insert(:transfer, %{
        from_balance: balance_4, to_balance: balance_3, status: "pending"
      }),
    }
  end

  describe "/transactions.all" do
    test "returns all the transactions", meta do
      response = provider_request("/transaction.all", %{
        "sort_by" => "created",
        "sort_dir" => "asc"
      })
      assert response["data"]["data"] |> length() == 8
      assert Enum.map(response["data"]["data"], fn t ->
        t["id"]
      end) == [
        meta.transfer_1.external_id,
        meta.transfer_2.external_id,
        meta.transfer_3.external_id,
        meta.transfer_4.external_id,
        meta.transfer_5.external_id,
        meta.transfer_6.external_id,
        meta.transfer_7.external_id,
        meta.transfer_8.external_id
      ]
    end

    test "returns all the transactions for a specific address", meta do
      response = provider_request("/transaction.all", %{
        "sort_by" => "created_at",
        "sort_dir" => "asc",
        "search_terms" => %{
          "from" => meta.balance_1.address,
          "to"   => meta.balance_2.address
        }
      })
      assert response["data"]["data"] |> length() == 4
      assert Enum.map(response["data"]["data"], fn t ->
        t["id"]
      end) == [
        meta.transfer_1.external_id,
        meta.transfer_3.external_id,
        meta.transfer_4.external_id,
        meta.transfer_7.external_id
      ]
    end

    test "returns all transactions filtered", meta do
      response = provider_request("/transaction.all", %{
        "sort_by" => "created_at",
        "sort_dir" => "asc",
        "search_term" => "pending"
      })
      assert response["data"]["data"] |> length() == 3
      assert Enum.map(response["data"]["data"], fn t ->
        t["id"]
      end) == [
        meta.transfer_4.external_id,
        meta.transfer_6.external_id,
        meta.transfer_8.external_id
      ]
    end

    test "returns all transactions sorted and paginated", meta do
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
      assert Enum.map(response["data"]["data"], fn t ->
        t["id"]
      end) == [
        meta.transfer_1.external_id,
        meta.transfer_2.external_id
      ]
    end
  end

  describe "/user.list_transactions" do
    test "returns all the transactions for a specific provider_user_id", meta do
      response = provider_request("/user.list_transactions", %{
        "sort_by" => "created_at",
        "sort_dir" => "asc",
        "provider_user_id" => meta.user.provider_user_id
      })
      assert response["data"]["data"] |> length() == 4
      assert Enum.map(response["data"]["data"], fn t ->
        t["id"]
      end) == [
        meta.transfer_1.external_id,
        meta.transfer_2.external_id,
        meta.transfer_3.external_id,
        meta.transfer_4.external_id
      ]
    end

    test "returns all the transactions for a specific provider_user_id and valid address", meta do
      response = provider_request("/user.list_transactions", %{
        "provider_user_id" => meta.user.provider_user_id,
        "address" => meta.balance_4.address
      })
      assert response["data"]["data"] |> length() == 2
      assert Enum.map(response["data"]["data"], fn t ->
        t["id"]
      end) == [
        meta.transfer_7.external_id,
        meta.transfer_8.external_id,
      ]
    end

    test "returns an 'user:user_balance_mismatch' error with provider_user_id and invalid address", meta do

      response = provider_request("/user.list_transactions", %{
        "provider_user_id" => meta.user.provider_user_id,
        "address" => meta.balance_2.address
      })
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "user:user_balance_mismatch"
      assert response["data"]["description"] ==
             "The provided balance does not belong to the current user"
    end

    test "returns the user's transactions even when different search terms are provided", meta do
      response = provider_request("/user.list_transactions", %{
        "provider_user_id" => meta.user.provider_user_id,
        "sort_by" => "created_at",
        "sort_dir" => "desc",
        "search_terms" => %{
          "from" => meta.balance_2.address,
          "to"   => meta.balance_2.address
        }
      })
      assert response["data"]["data"] |> length() == 4
      assert Enum.map(response["data"]["data"], fn t ->
        t["id"]
      end) == [
        meta.transfer_4.external_id,
        meta.transfer_3.external_id,
        meta.transfer_2.external_id,
        meta.transfer_1.external_id
      ]
    end

    test "returns all transactions filtered", meta do
      response = provider_request("/user.list_transactions", %{
        "provider_user_id" => meta.user.provider_user_id,
        "search_terms" => %{"status" => "pending"}
      })
      assert response["data"]["data"] |> length() == 1
      assert Enum.map(response["data"]["data"], fn t ->
        t["id"]
      end) == [
        meta.transfer_4.external_id
      ]
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
      assert Enum.map(response["data"]["data"], fn t ->
        t["id"]
      end) == [
        meta.transfer_1.external_id,
        meta.transfer_2.external_id
      ]
    end
  end

  describe "/me.list_transactions" do
    test "returns all the transactions for the current user", meta do
      response = client_request("/me.list_transactions", %{
        "sort_by" => "created_at"
      })
      assert response["data"]["data"] |> length() == 4
      assert Enum.map(response["data"]["data"], fn t ->
        t["id"]
      end) == [
        meta.transfer_1.external_id,
        meta.transfer_2.external_id,
        meta.transfer_3.external_id,
        meta.transfer_4.external_id
      ]
    end

    test "ignores search terms if both from and to are provided and
          address does not belong to user", meta do
      response = client_request("/me.list_transactions", %{
        "sort_by" => "created_at",
        "sort_dir" => "asc",
        "search_terms" => %{
          "from" => meta.balance_2.address,
          "to" => meta.balance_2.address
        }
      })

      assert response["data"]["data"] |> length() == 4
      assert Enum.map(response["data"]["data"], fn t ->
        t["id"]
      end) == [
        meta.transfer_1.external_id,
        meta.transfer_2.external_id,
        meta.transfer_3.external_id,
        meta.transfer_4.external_id
      ]
    end

    test "returns only the transactions sent to a specific balance with nil from", meta do
      response = client_request("/me.list_transactions", %{
        "search_terms" => %{
          "from" => nil,
          "to" => meta.balance_3.address
        }
      })

      assert response["data"]["data"] |> length() == 1
      assert Enum.map(response["data"]["data"], fn t ->
        t["id"]
      end) == [
        meta.transfer_3.external_id,
      ]
    end

    test "returns only the transactions sent to a specific balance", meta do
      response = client_request("/me.list_transactions", %{
        "search_terms" => %{
          "to" => meta.balance_3.address
        }
      })

      assert response["data"]["data"] |> length() == 1
      assert Enum.map(response["data"]["data"], fn t ->
        t["id"]
      end) == [
        meta.transfer_3.external_id,
      ]
    end

    test "returns all transactions for the current user sorted", meta do
      response = client_request("/me.list_transactions", %{
        "sort_by"  => "created_at",
        "sort_dir" => "desc"
      })

      assert response["data"]["data"] |> length() == 4
      assert Enum.map(response["data"]["data"], fn t ->
        t["id"]
      end) == [
        meta.transfer_4.external_id,
        meta.transfer_3.external_id,
        meta.transfer_2.external_id,
        meta.transfer_1.external_id
      ]
    end

    test "returns all transactions for the current user filtered", meta do
      response = client_request("/me.list_transactions", %{
        "search_terms" => %{"status" => "pending"}
      })

      assert response["data"]["data"] |> length() == 1
      assert Enum.map(response["data"]["data"], fn t ->
        t["id"]
      end) == [
        meta.transfer_4.external_id
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
        meta.transfer_3.external_id
      ]
    end
  end
end
