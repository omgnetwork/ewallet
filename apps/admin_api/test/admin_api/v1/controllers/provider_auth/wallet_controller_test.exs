defmodule AdminAPI.V1.ProviderAuth.WalletControllerTest do
  use AdminAPI.ConnCase, async: true
  alias EWallet.Web.Date
  alias EWallet.Web.V1.UserSerializer
  alias EWalletDB.{Account, AccountUser, Repo, Token, User, Wallet}

  describe "/wallet.all" do
    test "returns a list of wallets and pagination data" do
      response = provider_request("/wallet.all")

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
      insert(:wallet, %{address: "aaaa111111111111"})
      insert(:wallet, %{address: "aaaa333333333333"})
      insert(:wallet, %{address: "aaaa222222222222"})
      insert(:wallet, %{address: "bbbb111111111111"})

      attrs = %{
        # Search is case-insensitive
        "search_term" => "aAa",
        "sort_by" => "address",
        "sort_dir" => "desc"
      }

      response = provider_request("/wallet.all", attrs)
      wallets = response["data"]["data"]

      assert response["success"]
      assert Enum.count(wallets) == 3
      assert Enum.at(wallets, 0)["address"] == "aaaa333333333333"
      assert Enum.at(wallets, 1)["address"] == "aaaa222222222222"
      assert Enum.at(wallets, 2)["address"] == "aaaa111111111111"
    end
  end

  describe "/account.get_wallets" do
    test "returns a list of wallets and pagination data for the specified account" do
      {:ok, account} = :account |> params_for() |> Account.insert()
      response = provider_request("/account.get_wallets", %{"id" => account.id})

      # Asserts return data
      assert response["success"]
      assert response["data"]["object"] == "list"
      assert is_list(response["data"]["data"])

      wallets = response["data"]["data"]
      assert length(wallets) == 2

      wallets =
        Enum.map(wallets, fn wallet ->
          {wallet["account_id"], wallet["identifier"]}
        end)

      assert Enum.member?(wallets, {account.id, "primary"})
      assert Enum.member?(wallets, {account.id, "burn"})

      # Asserts pagination data
      pagination = response["data"]["pagination"]
      assert is_integer(pagination["per_page"])
      assert is_integer(pagination["current_page"])
      assert is_boolean(pagination["is_last_page"])
      assert is_boolean(pagination["is_first_page"])
    end

    test "returns a list of wallets according to sort_by and sort_direction" do
      account = insert(:account)

      insert(:wallet, %{
        account: account,
        address: "aaaa111111111111",
        identifier: "secondary_1"
      })

      insert(:wallet, %{
        account: account,
        address: "aaaa333333333333",
        identifier: "secondary_2"
      })

      insert(:wallet, %{
        account: account,
        address: "aaaa222222222222",
        identifier: "secondary_3"
      })

      insert(:wallet, %{
        account: account,
        address: "bbbb111111111111",
        identifier: "secondary_4"
      })

      attrs = %{
        "id" => account.id,
        # Search is case-insensitive
        "sort_by" => "address",
        "sort_dir" => "desc"
      }

      response = provider_request("/account.get_wallets", attrs)
      wallets = response["data"]["data"]

      assert response["success"]
      assert Enum.count(wallets) == 4
      assert Enum.at(wallets, 0)["address"] == "bbbb111111111111"
      assert Enum.at(wallets, 1)["address"] == "aaaa333333333333"
      assert Enum.at(wallets, 2)["address"] == "aaaa222222222222"
      assert Enum.at(wallets, 3)["address"] == "aaaa111111111111"

      Enum.each(wallets, fn wallet ->
        assert wallet["account_id"] == account.id
      end)
    end
  end

  describe "/user.get_wallets" do
    test "returns a list of wallets and pagination data for the specified user" do
      {:ok, user} = :user |> params_for() |> User.insert()
      response = provider_request("/user.get_wallets", %{"id" => user.id})

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

    test "returns a list of wallets according to sort_by and sort_direction" do
      user = insert(:user)
      insert(:wallet, %{user: user, address: "aaaa111111111111", identifier: "secondary_1"})
      insert(:wallet, %{user: user, address: "aaaa333333333333", identifier: "secondary_2"})
      insert(:wallet, %{user: user, address: "aaaa222222222222", identifier: "secondary_3"})
      insert(:wallet, %{user: user, address: "bbbb111111111111", identifier: "secondary_4"})

      attrs = %{
        "id" => user.id,
        "sort_by" => "address",
        "sort_dir" => "desc"
      }

      response = provider_request("/user.get_wallets", attrs)
      wallets = response["data"]["data"]

      assert response["success"]
      assert Enum.count(wallets) == 4
      assert Enum.at(wallets, 0)["address"] == "bbbb111111111111"
      assert Enum.at(wallets, 1)["address"] == "aaaa333333333333"
      assert Enum.at(wallets, 2)["address"] == "aaaa222222222222"
      assert Enum.at(wallets, 3)["address"] == "aaaa111111111111"

      Enum.each(wallets, fn wallet ->
        assert wallet["user_id"] == user.id
      end)
    end

    test "Get all user wallets from its provider_user_id" do
      account = Account.get_master_account()
      master_wallet = Account.get_primary_wallet(account)
      {:ok, user} = :user |> params_for() |> User.insert()
      user_wallet = User.get_primary_wallet(user)
      {:ok, btc} = :token |> params_for(symbol: "BTC") |> Token.insert()
      {:ok, omg} = :token |> params_for(symbol: "OMG") |> Token.insert()

      mint!(btc)
      mint!(omg)

      transfer!(master_wallet.address, user_wallet.address, btc, 150_000 * btc.subunit_to_unit)
      transfer!(master_wallet.address, user_wallet.address, omg, 12_000 * omg.subunit_to_unit)

      response =
        provider_request("/user.get_wallets", %{
          provider_user_id: user.provider_user_id
        })

      assert response == %{
               "version" => "1",
               "success" => true,
               "data" => %{
                 "object" => "list",
                 "pagination" => %{
                   "current_page" => 1,
                   "is_first_page" => true,
                   "is_last_page" => true,
                   "per_page" => 10
                 },
                 "data" => [
                   %{
                     "object" => "wallet",
                     "socket_topic" => "wallet:#{user_wallet.address}",
                     "address" => user_wallet.address,
                     "account" => nil,
                     "account_id" => nil,
                     "encrypted_metadata" => %{},
                     "identifier" => "primary",
                     "metadata" => %{},
                     "name" => "primary",
                     "user" => user |> UserSerializer.serialize() |> stringify_keys(),
                     "user_id" => user.id,
                     "enabled" => true,
                     "created_at" => Date.to_iso8601(user_wallet.inserted_at),
                     "updated_at" => Date.to_iso8601(user_wallet.updated_at),
                     "balances" => [
                       %{
                         "object" => "balance",
                         "amount" => 150_000 * btc.subunit_to_unit,
                         "token" => %{
                           "name" => btc.name,
                           "object" => "token",
                           "subunit_to_unit" => btc.subunit_to_unit,
                           "symbol" => btc.symbol,
                           "id" => btc.id,
                           "metadata" => %{},
                           "encrypted_metadata" => %{},
                           "enabled" => true,
                           "created_at" => Date.to_iso8601(btc.inserted_at),
                           "updated_at" => Date.to_iso8601(btc.updated_at)
                         }
                       },
                       %{
                         "object" => "balance",
                         "amount" => 12_000 * omg.subunit_to_unit,
                         "token" => %{
                           "name" => omg.name,
                           "object" => "token",
                           "subunit_to_unit" => omg.subunit_to_unit,
                           "symbol" => omg.symbol,
                           "id" => omg.id,
                           "metadata" => %{},
                           "encrypted_metadata" => %{},
                           "enabled" => true,
                           "created_at" => Date.to_iso8601(omg.inserted_at),
                           "updated_at" => Date.to_iso8601(omg.updated_at)
                         }
                       }
                     ]
                   }
                 ]
               }
             }
    end

    test "fails to get all user wallets with an invalid parameter" do
      request_data = %{some_invalid_param: "some_invalid_value"}
      response = provider_request("/user.get_wallets", request_data)

      assert response == %{
               "version" => "1",
               "success" => false,
               "data" => %{
                 "object" => "error",
                 "code" => "client:invalid_parameter",
                 "description" => "Invalid parameter provided.",
                 "messages" => nil
               }
             }
    end

    test "fails to get all user wallets with a nil provider_user_id" do
      request_data = %{provider_user_id: nil}
      response = provider_request("/user.get_wallets", request_data)

      assert response == %{
               "version" => "1",
               "success" => false,
               "data" => %{
                 "object" => "error",
                 "code" => "unauthorized",
                 "description" => "You are not allowed to perform the requested operation.",
                 "messages" => nil
               }
             }
    end

    test "Get all user wallets with a nil address should fail" do
      request_data = %{address: nil}
      response = provider_request("/user.get_wallets", request_data)

      assert response == %{
               "version" => "1",
               "success" => false,
               "data" => %{
                 "object" => "error",
                 "code" => "client:invalid_parameter",
                 "description" => "Invalid parameter provided.",
                 "messages" => nil
               }
             }
    end
  end

  describe "/wallet.get" do
    test "returns a wallet by the given ID" do
      account = Account.get_master_account()
      wallets = insert_list(3, :wallet)

      # Pick the 2nd inserted wallet
      target = Enum.at(wallets, 1)
      {:ok, _} = AccountUser.link(account.uuid, target.user_uuid)

      response = provider_request("/wallet.get", %{"address" => target.address})

      assert response["success"]
      assert response["data"]["object"] == "wallet"
      assert response["data"]["address"] == target.address
    end

    test "returns 'unauthorized' if the given ID was not found" do
      response = provider_request("/wallet.get", %{"address" => "fake-0000-0000-0000"})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "unauthorized"
    end

    test "returns 'client:invalid_parameter' if id was not provided" do
      response = provider_request("/wallet.get", %{"not_id" => "wallet_id"})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"
      assert response["data"]["description"] == "Invalid parameter provided."
    end
  end

  describe "/wallet.create" do
    test "fails to insert a primary wallet for an account" do
      account = insert(:account)

      response =
        provider_request("/wallet.create", %{
          name: "MyWallet",
          identifier: "primary",
          account_id: account.id
        })

      assert response["success"] == false

      assert response["data"] == %{
               "code" => "client:invalid_parameter",
               "description" => "Invalid parameter provided. `identifier` has invalid format.",
               "messages" => %{"identifier" => ["format"]},
               "object" => "error"
             }
    end

    test "inserts a secondary wallet for an account" do
      account = insert(:account)
      assert Wallet |> Repo.all() |> length() == 3

      response =
        provider_request("/wallet.create", %{
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
      assert length(wallets) == 4

      assert Enum.any?(wallets, fn wallet ->
               wallet.address == response["data"]["address"]
             end)
    end

    test "inserts a new burn wallet for an account" do
      account = insert(:account)
      assert Wallet |> Repo.all() |> length() == 3

      response =
        provider_request("/wallet.create", %{
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
      assert length(wallets) == 4

      assert Enum.any?(wallets, fn wallet ->
               wallet.address == response["data"]["address"]
             end)
    end

    test "fails to insert a primary wallet for a user" do
      user = insert(:user)

      response =
        provider_request("/wallet.create", %{
          name: "MyWallet",
          identifier: "primary",
          user_id: user.id
        })

      assert response["success"] == false

      assert response["data"] == %{
               "code" => "client:invalid_parameter",
               "description" => "Invalid parameter provided. `identifier` has invalid format.",
               "messages" => %{"identifier" => ["format"]},
               "object" => "error"
             }
    end

    test "inserts two secondary wallets for a user" do
      user = insert(:user)
      assert Wallet |> Repo.all() |> length() == 3

      response_1 =
        provider_request("/wallet.create", %{
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
        provider_request("/wallet.create", %{
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
      assert length(wallets) == 5

      assert Enum.any?(wallets, fn wallet ->
               wallet.address == response_1["data"]["address"]
             end)

      assert Enum.any?(wallets, fn wallet ->
               wallet.address == response_2["data"]["address"]
             end)
    end

    test "fails to insert a burn wallet for a user" do
      user = insert(:user)

      response =
        provider_request("/wallet.create", %{
          name: "MyWallet",
          identifier: "burn",
          user_id: user.id
        })

      assert response["success"] == false

      assert response["data"] == %{
               "code" => "client:invalid_parameter",
               "description" => "Invalid parameter provided. `account_id` can't be blank.",
               "messages" => %{"account_id" => ["required"]},
               "object" => "error"
             }
    end

    test "fails to insert a new wallet when both user and account are specified" do
      account = insert(:account)
      user = insert(:user)

      response =
        provider_request("/wallet.create", %{
          name: "MyWallet",
          identifier: "secondary",
          account_id: account.id,
          user_id: user.id
        })

      assert response["success"] == false

      assert response["data"] == %{
               "code" => "client:invalid_parameter",
               "description" =>
                 "Invalid parameter provided. `account_id`, `user_id` only one must be present.",
               "messages" => %{"account_id, user_id" => ["only_one_required"]},
               "object" => "error"
             }
    end

    test "fails to insert a new wallet if no account or user is specified" do
      response =
        provider_request("/wallet.create", %{
          name: "MyWallet",
          identifier: "burn"
        })

      assert response["success"] == false

      assert response["data"] == %{
               "code" => "unauthorized",
               "object" => "error",
               "description" => "You are not allowed to perform the requested operation.",
               "messages" => nil
             }
    end

    test "returns insert error when attrs are invalid" do
      account = Account.get_master_account()

      response =
        provider_request("/wallet.create", %{
          name: "MyWallet",
          account_id: account.id
        })

      refute response["success"]

      assert response["data"] == %{
               "code" => "client:invalid_parameter",
               "object" => "error",
               "description" => "Invalid parameter provided. `identifier` can't be blank.",
               "messages" => %{"identifier" => ["required"]}
             }

      # The account's wallets made to use the request
      length = Wallet |> Repo.all() |> length()
      assert length == 3
    end
  end
end
