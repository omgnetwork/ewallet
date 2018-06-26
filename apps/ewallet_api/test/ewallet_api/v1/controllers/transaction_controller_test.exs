defmodule EWalletAPI.V1.TransactionControllerTest do
  use EWalletAPI.ConnCase, async: false
  alias EWalletDB.User

  # credo:disable-for-next-line
  setup do
    user = get_test_user()
    wallet_1 = User.get_primary_wallet(user)
    wallet_2 = insert(:wallet)
    wallet_3 = insert(:wallet)
    wallet_4 = insert(:wallet, user: user, identifier: "secondary")

    transaction_1 =
      insert(:transaction, %{
        from_wallet: wallet_1,
        to_wallet: wallet_2,
        status: "confirmed"
      })

    transaction_2 =
      insert(:transaction, %{
        from_wallet: wallet_2,
        to_wallet: wallet_1,
        status: "confirmed"
      })

    transaction_3 =
      insert(:transaction, %{
        from_wallet: wallet_1,
        to_wallet: wallet_3,
        status: "confirmed"
      })

    transaction_4 =
      insert(:transaction, %{
        from_wallet: wallet_1,
        to_wallet: wallet_2,
        status: "pending"
      })

    transaction_5 = insert(:transaction, %{status: "confirmed"})
    transaction_6 = insert(:transaction, %{status: "pending"})

    transaction_7 =
      insert(:transaction, %{
        from_wallet: wallet_4,
        to_wallet: wallet_2,
        status: "confirmed"
      })

    transaction_8 =
      insert(:transaction, %{
        from_wallet: wallet_4,
        to_wallet: wallet_3,
        status: "pending"
      })

    %{
      user: user,
      wallet_1: wallet_1,
      wallet_2: wallet_2,
      wallet_3: wallet_3,
      wallet_4: wallet_4,
      transaction_1: transaction_1,
      transaction_2: transaction_2,
      transaction_3: transaction_3,
      transaction_4: transaction_4,
      transaction_5: transaction_5,
      transaction_6: transaction_6,
      transaction_7: transaction_7,
      transaction_8: transaction_8
    }
  end

  describe "/me.get_transactions" do
    test "returns all the transactions for the current user", meta do
      response =
        client_request("/me.get_transactions", %{
          "sort_by" => "created_at"
        })

      assert response["data"]["data"] |> length() == 4

      ids =
        Enum.map(response["data"]["data"], fn t ->
          t["id"]
        end)

      assert Enum.member?(ids, meta.transaction_1.id)
      assert Enum.member?(ids, meta.transaction_2.id)
      assert Enum.member?(ids, meta.transaction_3.id)
      assert Enum.member?(ids, meta.transaction_4.id)
    end

    test "ignores search terms if both from and to are provided and
          address does not belong to user",
         meta do
      response =
        client_request("/me.get_transactions", %{
          "sort_by" => "created_at",
          "sort_dir" => "asc",
          "search_terms" => %{
            "from" => meta.wallet_2.address,
            "to" => meta.wallet_2.address
          }
        })

      assert response["data"]["data"] |> length() == 4

      assert Enum.map(response["data"]["data"], fn t ->
               t["id"]
             end) == [
               meta.transaction_1.id,
               meta.transaction_2.id,
               meta.transaction_3.id,
               meta.transaction_4.id
             ]
    end

    test "returns only the transactions sent to a specific wallet with nil from", meta do
      response =
        client_request("/me.get_transactions", %{
          "search_terms" => %{
            "from" => nil,
            "to" => meta.wallet_3.address
          }
        })

      assert response["data"]["data"] |> length() == 1

      assert Enum.map(response["data"]["data"], fn t ->
               t["id"]
             end) == [
               meta.transaction_3.id
             ]
    end

    test "returns only the transactions sent to a specific wallet", meta do
      response =
        client_request("/me.get_transactions", %{
          "search_terms" => %{
            "to" => meta.wallet_3.address
          }
        })

      assert response["data"]["data"] |> length() == 1

      assert Enum.map(response["data"]["data"], fn t ->
               t["id"]
             end) == [
               meta.transaction_3.id
             ]
    end

    test "returns all transactions for the current user sorted", meta do
      response =
        client_request("/me.get_transactions", %{
          "sort_by" => "created_at",
          "sort_dir" => "desc"
        })

      assert response["data"]["data"] |> length() == 4

      assert Enum.map(response["data"]["data"], fn t ->
               t["id"]
             end) == [
               meta.transaction_4.id,
               meta.transaction_3.id,
               meta.transaction_2.id,
               meta.transaction_1.id
             ]
    end

    test "returns all transactions for the current user filtered", meta do
      response =
        client_request("/me.get_transactions", %{
          "search_terms" => %{"status" => "pending"}
        })

      assert response["data"]["data"] |> length() == 1

      assert Enum.map(response["data"]["data"], fn t ->
               t["id"]
             end) == [
               meta.transaction_4.id
             ]
    end

    test "returns all transactions for the current user paginated", meta do
      response =
        client_request("/me.get_transactions", %{
          "page" => 2,
          "per_page" => 1,
          "sort_by" => "created_at",
          "sort_dir" => "desc"
        })

      assert Enum.map(response["data"]["data"], fn t ->
               t["id"]
             end) == [
               meta.transaction_3.id
             ]
    end
  end
end
