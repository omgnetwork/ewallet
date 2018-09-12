defmodule EWalletAPI.V1.SelfControllerTest do
  use EWalletAPI.ConnCase, async: true
  alias EWallet.Web.Date
  alias EWalletDB.{Account, User}

  describe "/me.get" do
    test "responds with user data" do
      response = client_request("/me.get")

      assert response["success"]
      assert response["data"]["username"] == @username
    end
  end

  describe "/me.get_settings" do
    test "responds with a list of tokens" do
      response = client_request("/me.get_settings")

      assert response["success"]
      assert Map.has_key?(response["data"], "tokens")
      assert is_list(response["data"]["tokens"])
    end
  end

  describe "/me.get_wallets" do
    test "responds with a list of wallets" do
      account = Account.get_master_account()
      master_wallet = Account.get_primary_wallet(account)
      user = get_test_user()
      user_wallet = User.get_primary_wallet(user)
      btc = insert(:token, %{symbol: "BTC"})
      omg = insert(:token, %{symbol: "OMG"})

      mint!(btc)
      mint!(omg)

      transfer!(master_wallet.address, user_wallet.address, btc, 150_000 * btc.subunit_to_unit)
      transfer!(master_wallet.address, user_wallet.address, omg, 12_000 * omg.subunit_to_unit)

      response = client_request("/me.get_wallets")

      assert response == %{
               "version" => "1",
               "success" => true,
               "data" => %{
                 "object" => "list",
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
                     "enabled" => true,
                     "created_at" => Date.to_iso8601(user_wallet.inserted_at),
                     "updated_at" => Date.to_iso8601(user_wallet.updated_at),
                     "user" => %{
                       "avatar" => %{
                         "large" => nil,
                         "original" => nil,
                         "small" => nil,
                         "thumb" => nil
                       },
                       "created_at" => Date.to_iso8601(user.inserted_at),
                       "email" => nil,
                       "encrypted_metadata" => %{},
                       "id" => user.id,
                       "metadata" => user.metadata,
                       "object" => "user",
                       "provider_user_id" => user.provider_user_id,
                       "socket_topic" => "user:#{user.id}",
                       "updated_at" => Date.to_iso8601(user.updated_at),
                       "username" => user.username
                     },
                     "user_id" => user.id,
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
  end
end
