# Copyright 2018-2019 OmiseGO Pte Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule EWallet.AccountFetcherTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias EWallet.AccountFetcher
  alias EWalletDB.{Account, User}

  describe "fetch_exchange_account with token_id" do
    test "returns unmodified from" do
      token = insert(:token)

      res =
        AccountFetcher.fetch_exchange_account(
          %{
            "token_id" => token.id
          },
          %{}
        )

      assert res == {:ok, %{}}
    end
  end

  describe "fetch_exchange_account with from_token_id/to_token_id" do
    test "returns unmodified from when same token" do
      token = insert(:token)

      res =
        AccountFetcher.fetch_exchange_account(
          %{
            "from_token_id" => token.id,
            "to_token_id" => token.id
          },
          %{}
        )

      assert res == {:ok, %{}}
    end

    test "sets the token in from_token and to_token when different with
          exchange_account_id" do
      {:ok, account} = :account |> params_for() |> Account.insert()
      wallet = Account.get_primary_wallet(account)
      token_1 = insert(:token)
      token_2 = insert(:token)

      res =
        AccountFetcher.fetch_exchange_account(
          %{
            "from_token_id" => token_1.id,
            "to_token_id" => token_2.id,
            "exchange_account_id" => account.id
          },
          %{}
        )

      assert res ==
               {:ok,
                %{
                  exchange_account_uuid: account.uuid,
                  exchange_wallet_address: wallet.address
                }}
    end

    test "sets the token in from_token and to_token when different
          with valid exchange_wallet_address" do
      {:ok, account} = :account |> params_for() |> Account.insert()
      wallet = Account.get_primary_wallet(account)
      token_1 = insert(:token)
      token_2 = insert(:token)

      res =
        AccountFetcher.fetch_exchange_account(
          %{
            "from_token_id" => token_1.id,
            "to_token_id" => token_2.id,
            "exchange_wallet_address" => wallet.address
          },
          %{}
        )

      assert res ==
               {:ok,
                %{
                  exchange_account_uuid: account.uuid,
                  exchange_wallet_address: wallet.address
                }}
    end

    test "sets the token in from_token and to_token when different
          with valid exchange_account_id and exchange_wallet_address" do
      {:ok, account} = :account |> params_for() |> Account.insert()
      wallet = Account.get_primary_wallet(account)
      token_1 = insert(:token)
      token_2 = insert(:token)

      res =
        AccountFetcher.fetch_exchange_account(
          %{
            "from_token_id" => token_1.id,
            "to_token_id" => token_2.id,
            "exchange_account_id" => account.id,
            "exchange_wallet_address" => wallet.address
          },
          %{}
        )

      assert res ==
               {:ok,
                %{
                  exchange_account_uuid: account.uuid,
                  exchange_wallet_address: wallet.address
                }}
    end

    test "works when an admin user is making the tx even exchange pair doesn't allow it" do
      {:ok, account} = :account |> params_for() |> Account.insert()
      wallet = Account.get_primary_wallet(account)
      {:ok, admin} = :admin |> params_for() |> User.insert()
      token_1 = insert(:token)
      token_2 = insert(:token)

      exchange_pair =
        insert(:exchange_pair,
          from_token: token_1,
          to_token: token_2,
          default_exchange_wallet_address: wallet.address,
          allow_end_user_exchanges: false
        )

      {res, exchange} =
        AccountFetcher.fetch_exchange_account(
          %{
            "from_token_id" => token_1.id,
            "to_token_id" => token_2.id,
            "originator" => admin
          },
          %{pair: exchange_pair}
        )

      assert res == :ok
      assert exchange[:exchange_account_uuid] == account.uuid
      assert exchange[:exchange_wallet_address] == wallet.address
    end

    test "returns an error when there is a mismatch between exchange wallet account and address" do
      {:ok, account} = :account |> params_for() |> Account.insert()
      {:ok, user} = :user |> params_for() |> User.insert()
      wallet = User.get_primary_wallet(user)
      token_1 = insert(:token)
      token_2 = insert(:token)

      res =
        AccountFetcher.fetch_exchange_account(
          %{
            "from_token_id" => token_1.id,
            "to_token_id" => token_2.id,
            "exchange_account_id" => account.id,
            "exchange_wallet_address" => wallet.address
          },
          %{}
        )

      assert res == {:error, :account_wallet_mismatch}
    end

    test "returns an error when an end user is making the tx but exchange pair doesn't allow it" do
      {:ok, user} = :user |> params_for() |> User.insert()
      token_1 = insert(:token)
      token_2 = insert(:token)

      exchange_pair =
        insert(:exchange_pair,
          from_token: token_1,
          to_token: token_2,
          allow_end_user_exchanges: false
        )

      res =
        AccountFetcher.fetch_exchange_account(
          %{
            "from_token_id" => token_1.id,
            "to_token_id" => token_2.id,
            "originator" => user
          },
          %{pair: exchange_pair}
        )

      assert res == {:error, :end_user_exchanges_not_allowed}
    end

    test "sets the token in from_token and to_token when different
          with a user's address as exchange_wallet_address" do
      {:ok, user} = :user |> params_for() |> User.insert()
      wallet = User.get_primary_wallet(user)
      token_1 = insert(:token)
      token_2 = insert(:token)

      res =
        AccountFetcher.fetch_exchange_account(
          %{
            "from_token_id" => token_1.id,
            "to_token_id" => token_2.id,
            "exchange_wallet_address" => wallet.address
          },
          %{}
        )

      assert res == :exchange_address_not_account
    end

    test "sets the token in from_token and to_token when different
          without exchange_account_id/exchange_wallet_address" do
      token_1 = insert(:token)
      token_2 = insert(:token)

      res =
        AccountFetcher.fetch_exchange_account(
          %{
            "from_token_id" => token_1.id,
            "to_token_id" => token_2.id
          },
          %{}
        )

      assert res ==
               {:error, :invalid_parameter,
                "Invalid parameter provided. `exchange_account_id` or `exchange_wallet_address` is required.'"}
    end

    test "returns an error if from_token is not found" do
      token_2 = insert(:token)

      res =
        AccountFetcher.fetch_exchange_account(
          %{
            "from_token_id" => "fake",
            "to_token_id" => token_2.id
          },
          %{}
        )

      assert res ==
               {:error, :invalid_parameter,
                "Invalid parameter provided. `exchange_account_id` or `exchange_wallet_address` is required.'"}
    end

    test "returns an error if to_token is not found" do
      token_1 = insert(:token)

      res =
        AccountFetcher.fetch_exchange_account(
          %{
            "from_token_id" => "fake",
            "to_token_id" => token_1.id
          },
          %{}
        )

      assert res ==
               {:error, :invalid_parameter,
                "Invalid parameter provided. `exchange_account_id` or `exchange_wallet_address` is required.'"}
    end
  end

  describe "fetch_exchange_account with invalid params" do
    test "returns an error when given only from_token_id" do
      token = insert(:token)

      res =
        AccountFetcher.fetch_exchange_account(
          %{
            "from_token_id" => token.id
          },
          %{}
        )

      assert res ==
               {:error, :invalid_parameter,
                "Invalid parameter provided. `exchange_account_id` or `exchange_wallet_address` is required.'"}
    end

    test "returns an error when given only to_token_id" do
      token = insert(:token)

      res =
        AccountFetcher.fetch_exchange_account(
          %{
            "to_token_id" => token.id
          },
          %{}
        )

      assert res ==
               {:error, :invalid_parameter,
                "Invalid parameter provided. `exchange_account_id` or `exchange_wallet_address` is required.'"}
    end

    test "returns an error with invalid params" do
      res = AccountFetcher.fetch_exchange_account(%{}, %{})

      assert res ==
               {:error, :invalid_parameter,
                "Invalid parameter provided. `exchange_account_id` or `exchange_wallet_address` is required.'"}
    end
  end
end
