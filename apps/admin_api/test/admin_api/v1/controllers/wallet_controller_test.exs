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
      assert Enum.at(wallets, 0)["identifier"] == "burn"

      assert Enum.at(wallets, 1)["account_id"] == account.id
      assert Enum.at(wallets, 1)["identifier"] == "primary"

      # Asserts pagination data
      pagination = response["data"]["pagination"]
      assert is_integer(pagination["per_page"])
      assert is_integer(pagination["current_page"])
      assert is_boolean(pagination["is_last_page"])
      assert is_boolean(pagination["is_first_page"])
    end

    test "returns a list of wallets according to search_term, sort_by and sort_direction" do
      {:ok, account} = :account |> params_for() |> Account.insert()
      insert(:wallet, %{account: account, address: "XYZ1", identifier: "secondary_1"})
      insert(:wallet, %{account: account, address: "XYZ3", identifier: "secondary_2"})
      insert(:wallet, %{account: account, address: "XYZ2", identifier: "secondary_3"})
      insert(:wallet, %{account: account, address: "ZZZ1", identifier: "secondary_4"})

      attrs = %{
        "id" => account.id,
        # Search is case-insensitive
        "search_term" => "xYz",
        "sort_by" => "address",
        "sort_dir" => "desc"
      }

      response = user_request("/account.get_wallets", attrs)
      wallets = response["data"]["data"]

      assert response["success"]
      assert Enum.count(wallets) == 3
      assert Enum.at(wallets, 0)["address"] == "XYZ3"
      assert Enum.at(wallets, 1)["address"] == "XYZ2"
      assert Enum.at(wallets, 2)["address"] == "XYZ1"

      Enum.each(wallets, fn wallet ->
        assert wallet["account_id"] == account.id
      end)
    end
  end

  describe "/user.get_wallets" do
    test "returns a list of wallets and pagination data for the specified user" do
      {:ok, user} = :user |> params_for() |> User.insert()
      response = user_request("/user.get_wallets", %{"id" => user.id})

      # Asserts return data
      assert response["success"]
      assert response["data"]["object"] == "list"
      assert is_list(response["data"]["data"])

      wallets = response["data"]["data"]
      assert length(wallets) == 1
      assert Enum.at(wallets, 0)["user_id"] == user.id
      assert Enum.at(wallets, 0)["identifier"] == "primary"

      # Asserts pagination data
      pagination = response["data"]["pagination"]
      assert is_integer(pagination["per_page"])
      assert is_integer(pagination["current_page"])
      assert is_boolean(pagination["is_last_page"])
      assert is_boolean(pagination["is_first_page"])
    end

    test "returns a list of wallets according to search_term, sort_by and sort_direction" do
      {:ok, user} = :user |> params_for() |> User.insert()
      insert(:wallet, %{user: user, address: "XYZ1", identifier: "secondary_1"})
      insert(:wallet, %{user: user, address: "XYZ3", identifier: "secondary_2"})
      insert(:wallet, %{user: user, address: "XYZ2", identifier: "secondary_3"})
      insert(:wallet, %{user: user, address: "ZZZ1", identifier: "secondary_4"})

      attrs = %{
        "id" => user.id,
        # Search is case-insensitive
        "search_term" => "xYz",
        "sort_by" => "address",
        "sort_dir" => "desc"
      }

      response = user_request("/user.get_wallets", attrs)
      wallets = response["data"]["data"]

      assert response["success"]
      assert Enum.count(wallets) == 3
      assert Enum.at(wallets, 0)["address"] == "XYZ3"
      assert Enum.at(wallets, 1)["address"] == "XYZ2"
      assert Enum.at(wallets, 2)["address"] == "XYZ1"

      Enum.each(wallets, fn wallet ->
        assert wallet["user_id"] == user.id
      end)
    end
  end

  describe "/wallet.get" do
    test "returns a wallet by the given ID" do
      wallets = insert_list(3, :wallet)
      # Pick the 2nd inserted wallet
      target = Enum.at(wallets, 1)
      response = user_request("/wallet.get", %{"address" => target.address})

      assert response["success"]
      assert response["data"]["object"] == "wallet"
      assert response["data"]["address"] == target.address
    end

    test "returns 'wallet:address_not_found' if the given ID was not found" do
      response = user_request("/wallet.get", %{"address" => "wrong_address"})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "wallet:address_not_found"

      assert response["data"]["description"] ==
               "There is no wallet corresponding to the provided address."
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
    test "fails to insert a primary wallet for an account" do
      account = insert(:account)

      response =
        user_request("/wallet.create", %{
          name: "MyWallet",
          identifier: "primary",
          account_id: account.id
        })

      assert response["success"] == false

      assert response["data"] == %{
               "code" => "client:invalid_parameter",
               "description" => "Invalid parameter provided `identifier` has invalid format.",
               "messages" => %{"identifier" => ["format"]},
               "object" => "error"
             }
    end

    test "inserts a secondary wallet for an account" do
      account = insert(:account)
      assert Wallet |> Repo.all() |> length() == 2

      response =
        user_request("/wallet.create", %{
          name: "MyWallet",
          identifier: "secondary",
          account_id: account.id
        })

      assert response["success"]
      assert response["data"]["object"] == "wallet"
      assert response["data"]["account_id"] == account.id
      assert "secondary_" <> _ = response["data"]["identifier"]
      assert response["data"]["name"] == "MyWallet"

      wallets = Repo.all(Wallet)
      assert length(wallets) == 3
      assert Enum.at(wallets, 2).address == response["data"]["address"]
    end

    test "inserts a new burn wallet for an account" do
      account = insert(:account)
      assert Wallet |> Repo.all() |> length() == 2

      response =
        user_request("/wallet.create", %{
          name: "MyWallet",
          identifier: "burn",
          account_id: account.id
        })

      assert response["success"]
      assert response["data"]["object"] == "wallet"
      assert response["data"]["account_id"] == account.id
      assert "burn_" <> _ = response["data"]["identifier"]
      assert response["data"]["name"] == "MyWallet"

      wallets = Repo.all(Wallet)
      assert length(wallets) == 3
      assert Enum.at(wallets, 2).address == response["data"]["address"]
    end

    test "fails to insert a primary wallet for a user" do
      user = insert(:user)

      response =
        user_request("/wallet.create", %{
          name: "MyWallet",
          identifier: "primary",
          user_id: user.id
        })

      assert response["success"] == false

      assert response["data"] == %{
               "code" => "client:invalid_parameter",
               "description" => "Invalid parameter provided `identifier` has invalid format.",
               "messages" => %{"identifier" => ["format"]},
               "object" => "error"
             }
    end

    test "inserts two secondary wallets for a user" do
      user = insert(:user)
      assert Wallet |> Repo.all() |> length() == 2

      response_1 =
        user_request("/wallet.create", %{
          name: "MyWallet",
          identifier: "secondary",
          user_id: user.id
        })

      assert response_1["success"]
      assert response_1["data"]["object"] == "wallet"
      assert response_1["data"]["user_id"] == user.id
      assert "secondary_" <> _ = response_1["data"]["identifier"]
      assert response_1["data"]["name"] == "MyWallet"

      response_2 =
        user_request("/wallet.create", %{
          name: "MyWallet2",
          identifier: "secondary",
          user_id: user.id
        })

      assert response_2["success"]
      assert response_2["data"]["object"] == "wallet"
      assert response_2["data"]["user_id"] == user.id
      assert "secondary_" <> _ = response_2["data"]["identifier"]
      assert response_2["data"]["name"] == "MyWallet2"

      wallets = Repo.all(Wallet)
      assert length(wallets) == 4
      assert Enum.at(wallets, 2).address == response_1["data"]["address"]
      assert Enum.at(wallets, 3).address == response_2["data"]["address"]
    end

    test "fails to insert a burn wallet for a user" do
      user = insert(:user)

      response =
        user_request("/wallet.create", %{
          name: "MyWallet",
          identifier: "burn",
          user_id: user.id
        })

      assert response["success"] == false

      assert response["data"] == %{
               "code" => "client:invalid_parameter",
               "description" => "Invalid parameter provided `account_id` can't be blank.",
               "messages" => %{"account_id" => ["required"]},
               "object" => "error"
             }
    end

    test "fails to insert a new wallet when both user and account are specified" do
      account = insert(:account)
      user = insert(:user)

      response =
        user_request("/wallet.create", %{
          name: "MyWallet",
          identifier: "secondary",
          account_id: account.id,
          user_id: user.id
        })

      assert response["success"] == false

      assert response["data"] == %{
               "code" => "client:invalid_parameter",
               "description" =>
                 "Invalid parameter provided `account_id`, `user_id` only one must be present.",
               "messages" => %{"account_id, user_id" => ["only_one_required"]},
               "object" => "error"
             }
    end

    test "fails to insert a new wallet if no account or user is specified" do
      response =
        user_request("/wallet.create", %{
          name: "MyWallet",
          identifier: "burn"
        })

      assert response["success"] == false

      assert response["data"] == %{
               "code" => "client:invalid_parameter",
               "object" => "error",
               "description" =>
                 "Invalid parameter provided `account_id`, `user_id` can't all be blank. `account_id` can't be blank.",
               "messages" => %{
                 "account_id" => ["required"],
                 "account_id, user_id" => ["required_exclusive"]
               }
             }
    end

    test "returns insert error when attrs are invalid" do
      response =
        user_request("/wallet.create", %{
          name: "MyWallet"
        })

      refute response["success"]

      assert response["data"] == %{
               "code" => "client:invalid_parameter",
               "description" =>
                 "Invalid parameter provided `account_id`, `user_id` can't all be blank. `address` can't be blank. `identifier` can't be blank.",
               "messages" => %{
                 "account_id, user_id" => ["required_exclusive"],
                 "address" => ["required"],
                 "identifier" => ["required"]
               },
               "object" => "error"
             }

      # The account's wallets made to use the request
      length = Wallet |> Repo.all() |> length()
      assert length == 2
    end
  end
end
