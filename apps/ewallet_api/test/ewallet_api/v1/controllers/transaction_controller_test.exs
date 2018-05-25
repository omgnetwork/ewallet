defmodule EWalletAPI.V1.TransactionControllerTest do
  use EWalletAPI.ConnCase, async: false
  alias EWalletDB.User

  setup do
    user = get_test_user()
    wallet_1 = User.get_primary_wallet(user)
    wallet_2 = insert(:wallet)
    wallet_3 = insert(:wallet)
    wallet_4 = insert(:wallet, user: user, identifier: "secondary")

    transfer_1 =
      insert(:transfer, %{
        from_wallet: wallet_1,
        to_wallet: wallet_2,
        status: "confirmed"
      })

    transfer_2 =
      insert(:transfer, %{
        from_wallet: wallet_2,
        to_wallet: wallet_1,
        status: "confirmed"
      })

    transfer_3 =
      insert(:transfer, %{
        from_wallet: wallet_1,
        to_wallet: wallet_3,
        status: "confirmed"
      })

    transfer_4 =
      insert(:transfer, %{
        from_wallet: wallet_1,
        to_wallet: wallet_2,
        status: "pending"
      })

    transfer_5 = insert(:transfer, %{status: "confirmed"})
    transfer_6 = insert(:transfer, %{status: "pending"})

    transfer_7 =
      insert(:transfer, %{
        from_wallet: wallet_4,
        to_wallet: wallet_2,
        status: "confirmed"
      })

    transfer_8 =
      insert(:transfer, %{
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
      transfer_1: transfer_1,
      transfer_2: transfer_2,
      transfer_3: transfer_3,
      transfer_4: transfer_4,
      transfer_5: transfer_5,
      transfer_6: transfer_6,
      transfer_7: transfer_7,
      transfer_8: transfer_8
    }
  end

  describe "/transactions.all" do
    test "returns all the transactions", meta do
      response =
        provider_request("/transaction.all", %{
          "sort_by" => "created",
          "sort_dir" => "asc"
        })

      transfers = [
        meta.transfer_1,
        meta.transfer_2,
        meta.transfer_3,
        meta.transfer_4,
        meta.transfer_5,
        meta.transfer_6,
        meta.transfer_7,
        meta.transfer_8
      ]

      assert length(response["data"]["data"]) == length(transfers)

      # All transfers made during setup should exist in the response
      assert Enum.all?(transfers, fn transfer ->
               Enum.any?(response["data"]["data"], fn data ->
                 transfer.id == data["id"]
               end)
             end)
    end

    test "returns all the transactions for a specific address", meta do
      response =
        provider_request("/transaction.all", %{
          "sort_by" => "created_at",
          "sort_dir" => "asc",
          "search_terms" => %{
            "from" => meta.wallet_1.address,
            "to" => meta.wallet_2.address
          }
        })

      assert response["data"]["data"] |> length() == 4

      assert Enum.map(response["data"]["data"], fn t ->
               t["id"]
             end) == [
               meta.transfer_1.id,
               meta.transfer_3.id,
               meta.transfer_4.id,
               meta.transfer_7.id
             ]
    end

    test "returns all transactions filtered", meta do
      response =
        provider_request("/transaction.all", %{
          "sort_by" => "created_at",
          "sort_dir" => "asc",
          "search_term" => "pending"
        })

      assert response["data"]["data"] |> length() == 3

      assert Enum.map(response["data"]["data"], fn t ->
               t["id"]
             end) == [
               meta.transfer_4.id,
               meta.transfer_6.id,
               meta.transfer_8.id
             ]
    end

    test "returns all transactions sorted and paginated", meta do
      response =
        provider_request("/transaction.all", %{
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
               meta.transfer_1.id,
               meta.transfer_2.id
             ]
    end
  end

  describe "/user.list_transactions" do
    test "returns all the transactions for a specific provider_user_id", meta do
      response =
        provider_request("/user.list_transactions", %{
          "sort_by" => "created_at",
          "sort_dir" => "asc",
          "provider_user_id" => meta.user.provider_user_id
        })

      assert response["data"]["data"] |> length() == 4

      assert Enum.map(response["data"]["data"], fn t ->
               t["id"]
             end) == [
               meta.transfer_1.id,
               meta.transfer_2.id,
               meta.transfer_3.id,
               meta.transfer_4.id
             ]
    end

    test "returns all the transactions for a specific provider_user_id and valid address", meta do
      response =
        provider_request("/user.list_transactions", %{
          "provider_user_id" => meta.user.provider_user_id,
          "address" => meta.wallet_4.address
        })

      assert response["data"]["data"] |> length() == 2

      assert Enum.map(response["data"]["data"], fn t ->
               t["id"]
             end) == [
               meta.transfer_7.id,
               meta.transfer_8.id
             ]
    end

    test "returns an 'user:user_wallet_mismatch' error with provider_user_id and invalid address",
         meta do
      response =
        provider_request("/user.list_transactions", %{
          "provider_user_id" => meta.user.provider_user_id,
          "address" => meta.wallet_2.address
        })

      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "user:user_wallet_mismatch"

      assert response["data"]["description"] ==
               "The provided wallet does not belong to the current user"
    end

    test "returns the user's transactions even when different search terms are provided", meta do
      response =
        provider_request("/user.list_transactions", %{
          "provider_user_id" => meta.user.provider_user_id,
          "sort_by" => "created_at",
          "sort_dir" => "desc",
          "search_terms" => %{
            "from" => meta.wallet_2.address,
            "to" => meta.wallet_2.address
          }
        })

      assert response["data"]["data"] |> length() == 4

      assert Enum.map(response["data"]["data"], fn t ->
               t["id"]
             end) == [
               meta.transfer_4.id,
               meta.transfer_3.id,
               meta.transfer_2.id,
               meta.transfer_1.id
             ]
    end

    test "returns all transactions filtered", meta do
      response =
        provider_request("/user.list_transactions", %{
          "provider_user_id" => meta.user.provider_user_id,
          "search_terms" => %{"status" => "pending"}
        })

      assert response["data"]["data"] |> length() == 1

      assert Enum.map(response["data"]["data"], fn t ->
               t["id"]
             end) == [
               meta.transfer_4.id
             ]
    end

    test "returns all transactions sorted and paginated", meta do
      response =
        provider_request("/user.list_transactions", %{
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
               meta.transfer_1.id,
               meta.transfer_2.id
             ]
    end
  end

  describe "/me.list_transactions" do
    test "returns all the transactions for the current user", meta do
      response =
        client_request("/me.list_transactions", %{
          "sort_by" => "created_at"
        })

      assert response["data"]["data"] |> length() == 4

      ids = Enum.map(response["data"]["data"], fn t -> t["id"] end)
      assert length(ids) == 4
      assert Enum.member?(ids, meta.transfer_1.id)
      assert Enum.member?(ids, meta.transfer_2.id)
      assert Enum.member?(ids, meta.transfer_3.id)
      assert Enum.member?(ids, meta.transfer_4.id)
    end

    test "ignores search terms if both from and to are provided and
          address does not belong to user", meta do
      response =
        client_request("/me.list_transactions", %{
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
               meta.transfer_1.id,
               meta.transfer_2.id,
               meta.transfer_3.id,
               meta.transfer_4.id
             ]
    end

    test "returns only the transactions sent to a specific wallet with nil from", meta do
      response =
        client_request("/me.list_transactions", %{
          "search_terms" => %{
            "from" => nil,
            "to" => meta.wallet_3.address
          }
        })

      assert response["data"]["data"] |> length() == 1

      assert Enum.map(response["data"]["data"], fn t ->
               t["id"]
             end) == [
               meta.transfer_3.id
             ]
    end

    test "returns only the transactions sent to a specific wallet", meta do
      response =
        client_request("/me.list_transactions", %{
          "search_terms" => %{
            "to" => meta.wallet_3.address
          }
        })

      assert response["data"]["data"] |> length() == 1

      assert Enum.map(response["data"]["data"], fn t ->
               t["id"]
             end) == [
               meta.transfer_3.id
             ]
    end

    test "returns all transactions for the current user sorted", meta do
      response =
        client_request("/me.list_transactions", %{
          "sort_by" => "created_at",
          "sort_dir" => "desc"
        })

      assert response["data"]["data"] |> length() == 4

      assert Enum.map(response["data"]["data"], fn t ->
               t["id"]
             end) == [
               meta.transfer_4.id,
               meta.transfer_3.id,
               meta.transfer_2.id,
               meta.transfer_1.id
             ]
    end

    test "returns all transactions for the current user filtered", meta do
      response =
        client_request("/me.list_transactions", %{
          "search_terms" => %{"status" => "pending"}
        })

      assert response["data"]["data"] |> length() == 1

      assert Enum.map(response["data"]["data"], fn t ->
               t["id"]
             end) == [
               meta.transfer_4.id
             ]
    end

    test "returns all transactions for the current user paginated", meta do
      response =
        client_request("/me.list_transactions", %{
          "page" => 2,
          "per_page" => 1,
          "sort_by" => "created_at",
          "sort_dir" => "desc"
        })

      assert Enum.map(response["data"]["data"], fn t ->
               t["id"]
             end) == [
               meta.transfer_3.id
             ]
    end
  end
end
