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

defmodule EWallet.Web.V1.WalletSerializerTest do
  use EWallet.Web.SerializerCase, :v1
  alias Ecto.Adapters.SQL.Sandbox
  alias Ecto.Association.NotLoaded
  alias EWallet.BalanceFetcher
  alias EWallet.Web.Paginator
  alias EWallet.Web.V1.{AccountSerializer, BalanceSerializer, WalletSerializer, UserSerializer}
  alias EWalletDB.Helpers.Preloader
  alias LocalLedgerDB.Repo, as: LocalLedgerDBRepo
  alias Utils.Helpers.{Assoc, DateFormatter}

  setup do
    :ok = Sandbox.checkout(LocalLedgerDBRepo)
  end

  describe "serialize/1" do
    test "serializes a wallet into a wallet object" do
      wallet = insert(:wallet)
      {:ok, wallet} = BalanceFetcher.all(%{"wallet" => wallet})

      expected = %{
        object: "wallet",
        socket_topic: "wallet:#{wallet.address}",
        address: wallet.address,
        name: wallet.name,
        identifier: wallet.identifier,
        metadata: wallet.metadata,
        encrypted_metadata: wallet.encrypted_metadata,
        user_id: Assoc.get(wallet, [:user, :id]),
        user: UserSerializer.serialize(wallet.user),
        account_id: Assoc.get(wallet, [:account, :id]),
        account: AccountSerializer.serialize(wallet.account),
        balances: Enum.map(wallet.balances, &BalanceSerializer.serialize/1),
        enabled: wallet.enabled,
        created_at: DateFormatter.to_iso8601(wallet.inserted_at),
        updated_at: DateFormatter.to_iso8601(wallet.updated_at)
      }

      assert WalletSerializer.serialize(wallet) == expected
    end

    test "serializes a wallet paginator into a paginated list object" do
      wallet_1 = insert(:wallet)
      wallet_2 = insert(:wallet)
      {:ok, wallet_1} = BalanceFetcher.all(%{"wallet" => wallet_1})
      {:ok, wallet_2} = BalanceFetcher.all(%{"wallet" => wallet_2})

      paginator = %Paginator{
        data: [wallet_1, wallet_2],
        pagination: %{
          current_page: 9,
          per_page: 7,
          is_first_page: false,
          is_last_page: true
        }
      }

      expected = %{
        object: "list",
        data: [
          %{
            object: "wallet",
            socket_topic: "wallet:#{wallet_1.address}",
            address: wallet_1.address,
            name: wallet_1.name,
            identifier: wallet_1.identifier,
            metadata: wallet_1.metadata,
            encrypted_metadata: wallet_1.encrypted_metadata,
            user_id: Assoc.get(wallet_1, [:user, :id]),
            user: UserSerializer.serialize(wallet_1.user),
            account_id: Assoc.get(wallet_1, [:account, :id]),
            account: AccountSerializer.serialize(wallet_1.account),
            balances: Enum.map(wallet_1.balances, &BalanceSerializer.serialize/1),
            enabled: wallet_1.enabled,
            created_at: DateFormatter.to_iso8601(wallet_1.inserted_at),
            updated_at: DateFormatter.to_iso8601(wallet_1.updated_at)
          },
          %{
            object: "wallet",
            socket_topic: "wallet:#{wallet_2.address}",
            address: wallet_2.address,
            name: wallet_2.name,
            identifier: wallet_2.identifier,
            metadata: wallet_2.metadata,
            encrypted_metadata: wallet_2.encrypted_metadata,
            user_id: Assoc.get(wallet_2, [:user, :id]),
            user: UserSerializer.serialize(wallet_2.user),
            account_id: Assoc.get(wallet_2, [:account, :id]),
            account: AccountSerializer.serialize(wallet_2.account),
            balances: Enum.map(wallet_2.balances, &BalanceSerializer.serialize/1),
            enabled: wallet_2.enabled,
            created_at: DateFormatter.to_iso8601(wallet_2.inserted_at),
            updated_at: DateFormatter.to_iso8601(wallet_2.updated_at)
          }
        ],
        pagination: %{
          current_page: 9,
          per_page: 7,
          is_first_page: false,
          is_last_page: true
        }
      }

      assert WalletSerializer.serialize(paginator) == expected
    end

    test "serializes a wallet list into a list object" do
      wallet_1 = insert(:wallet)
      wallet_2 = insert(:wallet)
      {:ok, wallet_1} = BalanceFetcher.all(%{"wallet" => wallet_1})
      {:ok, wallet_2} = BalanceFetcher.all(%{"wallet" => wallet_2})

      wallet_list = [wallet_1, wallet_2]

      expected = %{
        object: "list",
        data: [
          %{
            object: "wallet",
            socket_topic: "wallet:#{wallet_1.address}",
            address: wallet_1.address,
            name: wallet_1.name,
            identifier: wallet_1.identifier,
            metadata: wallet_1.metadata,
            encrypted_metadata: wallet_1.encrypted_metadata,
            user_id: Assoc.get(wallet_1, [:user, :id]),
            user: UserSerializer.serialize(wallet_1.user),
            account_id: Assoc.get(wallet_1, [:account, :id]),
            account: AccountSerializer.serialize(wallet_1.account),
            balances: Enum.map(wallet_1.balances, &BalanceSerializer.serialize/1),
            enabled: wallet_1.enabled,
            created_at: DateFormatter.to_iso8601(wallet_1.inserted_at),
            updated_at: DateFormatter.to_iso8601(wallet_1.updated_at)
          },
          %{
            object: "wallet",
            socket_topic: "wallet:#{wallet_2.address}",
            address: wallet_2.address,
            name: wallet_2.name,
            identifier: wallet_2.identifier,
            metadata: wallet_2.metadata,
            encrypted_metadata: wallet_2.encrypted_metadata,
            user_id: Assoc.get(wallet_2, [:user, :id]),
            user: UserSerializer.serialize(wallet_2.user),
            account_id: Assoc.get(wallet_2, [:account, :id]),
            account: AccountSerializer.serialize(wallet_2.account),
            balances: Enum.map(wallet_2.balances, &BalanceSerializer.serialize/1),
            enabled: wallet_2.enabled,
            created_at: DateFormatter.to_iso8601(wallet_2.inserted_at),
            updated_at: DateFormatter.to_iso8601(wallet_2.updated_at)
          }
        ]
      }

      assert WalletSerializer.serialize(wallet_list) == expected
    end

    test "serializes to nil if the wallet is nil" do
      assert WalletSerializer.serialize(nil) == nil
    end

    test "serializes to nil if the wallet is not loaded" do
      assert WalletSerializer.serialize(%NotLoaded{}) == nil
    end
  end

  describe "serialize_without_balances/1" do
    test "serializes a wallet into a wallet object with `balances: nil`" do
      wallet = insert(:wallet)
      wallet = Preloader.preload(wallet, [:user, :account])

      expected = %{
        object: "wallet",
        socket_topic: "wallet:#{wallet.address}",
        address: wallet.address,
        name: wallet.name,
        identifier: wallet.identifier,
        metadata: wallet.metadata,
        encrypted_metadata: wallet.encrypted_metadata,
        user_id: Assoc.get(wallet, [:user, :id]),
        user: UserSerializer.serialize(wallet.user),
        account_id: Assoc.get(wallet, [:account, :id]),
        account: AccountSerializer.serialize(wallet.account),
        balances: nil,
        enabled: wallet.enabled,
        created_at: DateFormatter.to_iso8601(wallet.inserted_at),
        updated_at: DateFormatter.to_iso8601(wallet.updated_at)
      }

      assert WalletSerializer.serialize_without_balances(wallet) == expected
    end
  end
end
