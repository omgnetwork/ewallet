defmodule EWalletAPI.V1.WalletControllerTest do
  use EWalletAPI.ConnCase, async: true
  alias EWallet.Web.Date
  alias EWalletDB.{User, MintedToken, Account}
  alias EWallet.Web.V1.UserSerializer

  describe "/all" do
    test "Get all user wallets from its provider_user_id" do
      account = Account.get_master_account()
      master_wallet = Account.get_primary_wallet(account)
      {:ok, user} = :user |> params_for() |> User.insert()
      user_wallet = User.get_primary_wallet(user)
      {:ok, btc} = :minted_token |> params_for(symbol: "BTC") |> MintedToken.insert()
      {:ok, omg} = :minted_token |> params_for(symbol: "OMG") |> MintedToken.insert()

      mint!(btc)
      mint!(omg)

      transfer!(master_wallet.address, user_wallet.address, btc, 150_000 * btc.subunit_to_unit)
      transfer!(master_wallet.address, user_wallet.address, omg, 12_000 * omg.subunit_to_unit)

      response =
        provider_request("/user.list_wallets", %{
          provider_user_id: user.provider_user_id
        })

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
                     "user" => user |> UserSerializer.serialize() |> stringify_keys(),
                     "user_id" => user.id,
                     "balances" => [
                       %{
                         "object" => "balance",
                         "amount" => 150_000 * btc.subunit_to_unit,
                         "minted_token" => %{
                           "name" => btc.name,
                           "object" => "minted_token",
                           "subunit_to_unit" => btc.subunit_to_unit,
                           "symbol" => btc.symbol,
                           "id" => btc.id,
                           "metadata" => %{},
                           "encrypted_metadata" => %{},
                           "created_at" => Date.to_iso8601(btc.inserted_at),
                           "updated_at" => Date.to_iso8601(btc.updated_at)
                         }
                       },
                       %{
                         "object" => "balance",
                         "amount" => 12_000 * omg.subunit_to_unit,
                         "minted_token" => %{
                           "name" => omg.name,
                           "object" => "minted_token",
                           "subunit_to_unit" => omg.subunit_to_unit,
                           "symbol" => omg.symbol,
                           "id" => omg.id,
                           "metadata" => %{},
                           "encrypted_metadata" => %{},
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

    test "Get all user wallets from an address" do
      account = Account.get_master_account()
      master_wallet = Account.get_primary_wallet(account)
      {:ok, user} = :user |> params_for() |> User.insert()
      user_wallet = User.get_primary_wallet(user)
      {:ok, btc} = :minted_token |> params_for(symbol: "BTC") |> MintedToken.insert()
      {:ok, omg} = :minted_token |> params_for(symbol: "OMG") |> MintedToken.insert()

      mint!(btc)
      mint!(omg)

      transfer!(master_wallet.address, user_wallet.address, btc, 150_000 * btc.subunit_to_unit)
      transfer!(master_wallet.address, user_wallet.address, omg, 12_000 * omg.subunit_to_unit)

      response =
        provider_request("/user.list_wallets", %{
          address: user_wallet.address
        })

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
                     "user" => user |> UserSerializer.serialize() |> stringify_keys(),
                     "user_id" => user.id,
                     "balances" => [
                       %{
                         "object" => "balance",
                         "amount" => 150_000 * btc.subunit_to_unit,
                         "minted_token" => %{
                           "name" => btc.name,
                           "object" => "minted_token",
                           "subunit_to_unit" => btc.subunit_to_unit,
                           "symbol" => btc.symbol,
                           "id" => btc.id,
                           "metadata" => %{},
                           "encrypted_metadata" => %{},
                           "created_at" => Date.to_iso8601(btc.inserted_at),
                           "updated_at" => Date.to_iso8601(btc.updated_at)
                         }
                       },
                       %{
                         "object" => "balance",
                         "amount" => 12_000 * omg.subunit_to_unit,
                         "minted_token" => %{
                           "name" => omg.name,
                           "object" => "minted_token",
                           "subunit_to_unit" => omg.subunit_to_unit,
                           "symbol" => omg.symbol,
                           "id" => omg.id,
                           "metadata" => %{},
                           "encrypted_metadata" => %{},
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

    test "Get all user wallets with an invalid parameter should fail" do
      request_data = %{some_invalid_param: "some_invalid_value"}
      response = provider_request("/user.list_wallets", request_data)

      assert response == %{
               "version" => "1",
               "success" => false,
               "data" => %{
                 "object" => "error",
                 "code" => "client:invalid_parameter",
                 "description" => "Invalid parameter provided",
                 "messages" => nil
               }
             }
    end

    test "Get all user wallets with a nil provider_user_id should fail" do
      request_data = %{provider_user_id: nil}
      response = provider_request("/user.list_wallets", request_data)

      assert response == %{
               "version" => "1",
               "success" => false,
               "data" => %{
                 "object" => "error",
                 "code" => "client:invalid_parameter",
                 "description" => "Invalid parameter provided",
                 "messages" => nil
               }
             }
    end

    test "Get all user wallets with a nil address should fail" do
      request_data = %{address: nil}
      response = provider_request("/user.list_wallets", request_data)

      assert response == %{
               "version" => "1",
               "success" => false,
               "data" => %{
                 "object" => "error",
                 "code" => "client:invalid_parameter",
                 "description" => "Invalid parameter provided",
                 "messages" => nil
               }
             }
    end
  end
end
