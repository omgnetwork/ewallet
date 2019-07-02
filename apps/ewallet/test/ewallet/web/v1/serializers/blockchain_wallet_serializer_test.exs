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

defmodule EWallet.Web.V1.BlockchainWalletSerializerTest do
  use EWallet.Web.SerializerCase, :v1
  alias Ecto.Association.NotLoaded
  alias EWallet.Web.Paginator
  alias EWallet.Web.V1.BlockchainWalletSerializer
  alias Utils.Helpers.DateFormatter

  describe "serialize/1" do
    test "serializes a blockchain wallet into a blockchain wallet object" do
      wallet = insert(:blockchain_wallet)

      expected = %{
        object: "blockchain_wallet",
        address: wallet.address,
        name: wallet.name,
        type: wallet.type,
        created_at: DateFormatter.to_iso8601(wallet.inserted_at),
        updated_at: DateFormatter.to_iso8601(wallet.updated_at)
      }

      assert BlockchainWalletSerializer.serialize(wallet) == expected
    end

    test "serializes a wallet paginator into a paginated list object" do
      wallet_1 = insert(:blockchain_wallet)
      wallet_2 = insert(:blockchain_wallet)

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
            object: "blockchain_wallet",
            address: wallet_1.address,
            name: wallet_1.name,
            type: wallet_1.type,
            created_at: DateFormatter.to_iso8601(wallet_1.inserted_at),
            updated_at: DateFormatter.to_iso8601(wallet_1.updated_at)
          },
          %{
            object: "blockchain_wallet",
            address: wallet_2.address,
            name: wallet_2.name,
            type: wallet_2.type,
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

      assert BlockchainWalletSerializer.serialize(paginator) == expected
    end

    test "serializes a blockchain wallet list into a list object" do
      wallet_1 = insert(:blockchain_wallet)
      wallet_2 = insert(:blockchain_wallet)

      wallet_list = [wallet_1, wallet_2]

      expected = %{
        object: "list",
        data: [
          %{
            object: "blockchain_wallet",
            address: wallet_1.address,
            name: wallet_1.name,
            type: wallet_1.type,
            created_at: DateFormatter.to_iso8601(wallet_1.inserted_at),
            updated_at: DateFormatter.to_iso8601(wallet_1.updated_at)
          },
          %{
            object: "blockchain_wallet",
            address: wallet_2.address,
            name: wallet_2.name,
            type: wallet_2.type,
            created_at: DateFormatter.to_iso8601(wallet_2.inserted_at),
            updated_at: DateFormatter.to_iso8601(wallet_2.updated_at)
          }
        ]
      }

      assert BlockchainWalletSerializer.serialize(wallet_list) == expected
    end

    test "serializes to nil if the blockchain wallet is nil" do
      assert BlockchainWalletSerializer.serialize(nil) == nil
    end

    test "serializes to nil if the blockchain wallet is not loaded" do
      assert BlockchainWalletSerializer.serialize(%NotLoaded{}) == nil
    end
  end
end
