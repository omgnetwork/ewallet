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

      assert Enum.member?(ids, meta.transfer_1.id)
      assert Enum.member?(ids, meta.transfer_2.id)
      assert Enum.member?(ids, meta.transfer_3.id)
      assert Enum.member?(ids, meta.transfer_4.id)
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
               meta.transfer_1.id,
               meta.transfer_2.id,
               meta.transfer_3.id,
               meta.transfer_4.id
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
               meta.transfer_3.id
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
               meta.transfer_3.id
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
               meta.transfer_4.id,
               meta.transfer_3.id,
               meta.transfer_2.id,
               meta.transfer_1.id
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
               meta.transfer_4.id
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
               meta.transfer_3.id
             ]
    end
  end
end
