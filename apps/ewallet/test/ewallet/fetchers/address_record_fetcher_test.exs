# Copyright 2018 OmiseGO Pte Ltd
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

defmodule EWallet.AddressRecordFetcherTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias EWallet.AddressRecordFetcher
  alias Utils.Types.WalletAddress
  alias Utils.Types.ExternalID

  describe "fetch/3" do
    setup do
      wallet_1 = insert(:wallet)
      wallet_2 = insert(:wallet)
      token = insert(:token)

      %{
        wallet_1: wallet_1,
        wallet_2: wallet_2,
        token: token
      }
    end

    test "returns from_wallet, to_wallet, and token", context do
      attrs = %{
        "from_address" => context.wallet_1.address,
        "to_address" => context.wallet_2.address,
        "token_id" => context.token.id
      }

      {res, from_wallet, to_wallet, token} = AddressRecordFetcher.fetch(attrs)

      assert res == :ok
      assert from_wallet.uuid == context.wallet_1.uuid
      assert to_wallet.uuid == context.wallet_2.uuid
      assert token.uuid == context.token.uuid
    end

    test "returns :from_address_not_found when from_address is invalid", context do
      {:ok, fake_address} = WalletAddress.generate()

      attrs = %{
        "from_address" => fake_address,
        "to_address" => context.wallet_2.address,
        "token_id" => context.token.id
      }

      {res, reason} = AddressRecordFetcher.fetch(attrs)

      assert res == :error
      assert reason == :from_address_not_found
    end

    test "returns :to_address_not_found when to_address is invalid", context do
      {:ok, fake_address} = WalletAddress.generate()

      attrs = %{
        "from_address" => context.wallet_1.address,
        "to_address" => fake_address,
        "token_id" => context.token.id
      }

      {res, reason} = AddressRecordFetcher.fetch(attrs)

      assert res == :error
      assert reason == :to_address_not_found
    end

    test "returns :token_not_found when token_id is invalid", context do
      attrs = %{
        "from_address" => context.wallet_1.address,
        "to_address" => context.wallet_2.address,
        "token_id" => ExternalID.generate("tok_")
      }

      {res, reason} = AddressRecordFetcher.fetch(attrs)

      assert res == :error
      assert reason == :token_not_found
    end
  end
end
