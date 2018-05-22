defmodule AdminAPI.V1.WalletControllerTest do
  use AdminAPI.ConnCase, async: true
  alias EWalletDB.{Repo, Wallet, Account, User}

  describe "/wallet.all" do
    test "returns a list of wallets and pagination data" do
      response = user_request("/wallet.all")

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

    test "returns a list of wallets according to search_term, sort_by and sort_direction" do
      insert(:wallet, %{address: "XYZ1"})
      insert(:wallet, %{address: "XYZ3"})
      insert(:wallet, %{address: "XYZ2"})
      insert(:wallet, %{address: "ZZZ1"})

      attrs = %{
        # Search is case-insensitive
        "search_term" => "xYz",
        "sort_by" => "address",
        "sort_dir" => "desc"
      }

      response = user_request("/wallet.all", attrs)
      wallets = response["data"]["data"]

      assert response["success"]
      assert Enum.count(wallets) == 3
      assert Enum.at(wallets, 0)["address"] == "XYZ3"
      assert Enum.at(wallets, 1)["address"] == "XYZ2"
      assert Enum.at(wallets, 2)["address"] == "XYZ1"
    end
  end

  describe "/account.get_wallets" do
    test "returns a list of wallets and pagination data for the specified account" do
      {:ok, account} = :account |> params_for() |> Account.insert()
      response = user_request("/account.get_wallets", %{"id" => account.id})

      # Asserts return data
      assert response["success"]
      assert response["data"]["object"] == "list"
      assert is_list(response["data"]["data"])

      wallets = response["data"]["data"]
      assert length(wallets) == 2
      assert Enum.at(wallets, 0)["account_id"] == account.id
      assert Enum.at(wallets, 0)["identifier"] == "primary"
      assert Enum.at(wallets, 1)["account_id"] == account.id
      assert Enum.at(wallets, 1)["identifier"] == "burn"

      # Asserts pagination data
      pagination = response["data"]["pagination"]
      assert is_integer(pagination["per_page"])
      assert is_integer(pagination["current_page"])
      assert is_boolean(pagination["is_last_page"])
      assert is_boolean(pagination["is_first_page"])
    end

    test "returns a list of wallets according to search_term, sort_by and sort_direction" do
      insert(:wallet, %{address: "XYZ1"})
      insert(:wallet, %{address: "XYZ3"})
      insert(:wallet, %{address: "XYZ2"})
      insert(:wallet, %{address: "ZZZ1"})

      attrs = %{
        # Search is case-insensitive
        "search_term" => "xYz",
        "sort_by" => "address",
        "sort_dir" => "desc"
      }

      response = user_request("/wallet.all", attrs)
      wallets = response["data"]["data"]

      assert response["success"]
      assert Enum.count(wallets) == 3
      assert Enum.at(wallets, 0)["address"] == "XYZ3"
      assert Enum.at(wallets, 1)["address"] == "XYZ2"
      assert Enum.at(wallets, 2)["address"] == "XYZ1"
    end
  end

  describe "/user.get_wallets" do

  end

  describe "/wallet.get" do
    test "returns a wallet by the given ID" do
      wallets = insert_list(3, :wallet)
      # Pick the 2nd inserted wallet
      target = Enum.at(wallets, 1)
      response = user_request("/wallet.get", %{"id" => target.id})

      assert response["success"]
      assert response["data"]["object"] == "wallet"
      assert response["data"]["id"] == target.id
    end

    test "returns 'wallet:id_not_found' if the given ID was not found" do
      response = user_request("/wallet.get", %{"id" => "wrong_id"})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "wallet:id_not_found"

      assert response["data"]["description"] ==
               "There is no wallet corresponding to the provided id"
    end

    test "returns 'client:invalid_parameter' if id was not provided" do
      response = user_request("/wallet.get", %{"not_id" => "wallet_id"})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"
      assert response["data"]["description"] == "Invalid parameter provided"
    end
  end

  describe "/wallet.create" do
    test "inserts a new wallet" do
      response =
        user_request("/wallet.create", %{
          symbol: "BTC",
          name: "Bitcoin",
          description: "desc",
          subunit_to_unit: 100,
          metadata: %{something: "interesting"},
          encrypted_metadata: %{something: "secret"}
        })

      mint = Mint |> Repo.all() |> Enum.at(0)

      assert response["success"]
      assert response["data"]["object"] == "wallet"
      assert response["data"]["metadata"] == %{"something" => "interesting"}
      assert response["data"]["encrypted_metadata"] == %{"something" => "secret"}
      assert Wallet.get(response["data"]["id"]) != nil
      assert mint == nil
    end

    test "inserts a new wallet with no minting if amount is nil" do
      response =
        user_request("/wallet.create", %{
          symbol: "BTC",
          name: "Bitcoin",
          description: "desc",
          subunit_to_unit: 100,
          amount: nil
        })

      mint = Mint |> Repo.all() |> Enum.at(0)

      assert response["success"]
      assert response["data"]["object"] == "wallet"
      assert Wallet.get(response["data"]["id"]) != nil
      assert mint == nil
    end

    test "inserts a new wallet with no minting if amount is a string" do
      response =
        user_request("/wallet.create", %{
          symbol: "BTC",
          name: "Bitcoin",
          description: "desc",
          subunit_to_unit: 100,
          amount: "100"
        })

      mint = Mint |> Repo.all() |> Enum.at(0)

      assert response["success"]
      assert response["data"]["object"] == "wallet"
      assert Wallet.get(response["data"]["id"]) != nil
      assert mint == nil
    end

    test "fails a new wallet with no minting if amount is 0" do
      response =
        user_request("/wallet.create", %{
          symbol: "BTC",
          name: "Bitcoin",
          description: "desc",
          subunit_to_unit: 100,
          amount: 0
        })

      mint = Mint |> Repo.all() |> Enum.at(0)

      assert response["success"]
      assert response["data"]["object"] == "wallet"
      assert Wallet.get(response["data"]["id"]) != nil
      assert mint == nil
    end

    test "mints the given amount of wallets" do
      response =
        user_request("/wallet.create", %{
          symbol: "BTC",
          name: "Bitcoin",
          description: "desc",
          subunit_to_unit: 100,
          amount: 1_000 * 100
        })

      mint = Mint |> Repo.all() |> Enum.at(0)

      assert response["success"]
      assert response["data"]["object"] == "wallet"
      assert Wallet.get(response["data"]["id"]) != nil
      assert mint != nil
      assert mint.confirmed == true
    end

    test "returns insert error when attrs are invalid" do
      response =
        user_request("/wallet.create", %{
          name: "Bitcoin",
          description: "desc",
          subunit_to_unit: 100
        })

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"

      assert response["data"]["description"] ==
               "Invalid parameter provided `symbol` can't be blank."

      inserted = Wallet |> Repo.all() |> Enum.at(0)
      assert inserted == nil
    end
  end
end
