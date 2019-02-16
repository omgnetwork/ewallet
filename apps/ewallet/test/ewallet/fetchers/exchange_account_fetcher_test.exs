# Copyright 2019 OmiseGO Pte Ltd
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

defmodule EWallet.ExchangeAccountFetcherTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias EWallet.ExchangeAccountFetcher
  alias Utils.Types.ExternalID
  alias Utils.Types.WalletAddress

  setup do
    account = insert(:account)
    wallet = insert(:wallet, account: account, user: nil)

    %{
      account: account,
      wallet: wallet
    }
  end

  describe "fetch/1 with both exchange_account_id and exchange_wallet_address provided" do
    test "returns the wallet if the wallet address matches the account id", context do
      attrs = %{
        "exchange_account_id" => context.account.id,
        "exchange_wallet_address" => context.wallet.address
      }

      {res, exchange_wallet} = ExchangeAccountFetcher.fetch(attrs)

      assert res == :ok
      assert exchange_wallet.uuid == context.wallet.uuid
      assert exchange_wallet.account_uuid == context.account.uuid
    end

    test "returns :exchange_account_id_not_found if account id is invalid", context do
      attrs = %{
        "exchange_account_id" => ExternalID.generate("acc_"),
        "exchange_wallet_address" => context.wallet.address
      }

      {res, reason} = ExchangeAccountFetcher.fetch(attrs)

      assert res == :error
      assert reason == :exchange_account_id_not_found
    end

    test "returns :exchange_account_wallet_not_found if wallet address id is invalid", context do
      {:ok, fake_address} = WalletAddress.generate()

      attrs = %{
        "exchange_account_id" => context.account.id,
        "exchange_wallet_address" => fake_address
      }

      {res, reason} = ExchangeAccountFetcher.fetch(attrs)

      assert res == :error
      assert reason == :exchange_account_wallet_not_found
    end

    test "returns :exchange_account_wallet_mismatch if the wallet does not belong to the account",
         context do
      attrs = %{
        "exchange_account_id" => context.account.id,
        "exchange_wallet_address" => insert(:wallet).address
      }

      {res, reason} = ExchangeAccountFetcher.fetch(attrs)

      assert res == :error
      assert reason == :exchange_account_wallet_mismatch
    end
  end

  describe "fetch/1 with only exchange_account_id provided" do
    test "returns the exchange account's wallet if only the account id is provided", context do
      attrs = %{
        "exchange_account_id" => context.account.id
      }

      {res, exchange_wallet} = ExchangeAccountFetcher.fetch(attrs)

      assert res == :ok
      assert exchange_wallet.uuid == context.wallet.uuid
      assert exchange_wallet.account_uuid == context.account.uuid
    end

    test "returns :exchange_account_id_not_found if account id is invalid", _context do
      attrs = %{
        "exchange_account_id" => ExternalID.generate("acc_")
      }

      {res, reason} = ExchangeAccountFetcher.fetch(attrs)

      assert res == :error
      assert reason == :exchange_account_id_not_found
    end
  end

  describe "fetch/1 with only exchange_wallet_address" do
    test "returns the exchange wallet if only the wallet address is provided", context do
      attrs = %{
        "exchange_wallet_address" => context.wallet.address
      }

      {res, exchange_wallet} = ExchangeAccountFetcher.fetch(attrs)

      assert res == :ok
      assert exchange_wallet.uuid == context.wallet.uuid
      assert exchange_wallet.account_uuid == context.account.uuid
    end

    test "returns :exchange_address_not_account if wallet address is owned by a user", _context do
      wallet = insert(:wallet, user: insert(:user), account: nil)

      attrs = %{
        "exchange_wallet_address" => wallet.address
      }

      {res, reason} = ExchangeAccountFetcher.fetch(attrs)

      assert res == :error
      assert reason == :exchange_address_not_account
    end

    test "returns :exchange_account_wallet_not_found if wallet address is invalid", _context do
      {:ok, fake_address} = WalletAddress.generate()

      attrs = %{
        "exchange_wallet_address" => fake_address
      }

      {res, reason} = ExchangeAccountFetcher.fetch(attrs)

      assert res == :error
      assert reason == :exchange_account_wallet_not_found
    end
  end

  describe "fetch/1 with no related attributes" do
    test "returns a successful nil" do
      assert ExchangeAccountFetcher.fetch(%{foo: "bar"}) == {:ok, nil}
    end
  end
end
