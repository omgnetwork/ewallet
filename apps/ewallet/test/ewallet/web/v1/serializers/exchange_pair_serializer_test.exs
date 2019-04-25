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

defmodule EWallet.Web.V1.ExchangePairSerializerTest do
  use EWallet.Web.SerializerCase, :v1
  alias Ecto.Association.NotLoaded
  alias EWallet.Web.Paginator
  alias EWallet.ExchangePairGate
  alias EWallet.Web.V1.{ExchangePairSerializer, TokenSerializer}
  alias EWalletDB.ExchangePair
  alias Utils.Helpers.DateFormatter

  describe "serialize/1" do
    test "serializes an exchange pair into V1 response format" do
      exchange_pair = :exchange_pair |> insert() |> ExchangePairGate.add_opposite_pair()

      expected = %{
        object: "exchange_pair",
        id: exchange_pair.id,
        name: ExchangePair.get_name(exchange_pair),
        from_token_id: exchange_pair.from_token.id,
        from_token: TokenSerializer.serialize(exchange_pair.from_token),
        to_token_id: exchange_pair.to_token.id,
        to_token: TokenSerializer.serialize(exchange_pair.to_token),
        rate: exchange_pair.rate,
        created_at: DateFormatter.to_iso8601(exchange_pair.inserted_at),
        updated_at: DateFormatter.to_iso8601(exchange_pair.updated_at),
        default_exchange_wallet_address: exchange_pair.default_exchange_wallet_address,
        allow_end_user_exchanges: exchange_pair.allow_end_user_exchanges,
        opposite_exchange_pair_id: nil,
        opposite_exchange_pair: nil,
        deleted_at: nil
      }

      assert ExchangePairSerializer.serialize(exchange_pair) == expected
    end

    test "serializes an exchange pair and its opposite into V1 response format" do
      token_1 = insert(:token)
      token_2 = insert(:token)
      opposite_pair = insert(:exchange_pair, from_token: token_2, to_token: token_1)

      exchange_pair =
        :exchange_pair
        |> insert(%{from_token: token_1, to_token: token_2})
        |> ExchangePairGate.add_opposite_pair()

      expected = %{
        object: "exchange_pair",
        id: exchange_pair.id,
        name: ExchangePair.get_name(exchange_pair),
        from_token_id: exchange_pair.from_token.id,
        from_token: TokenSerializer.serialize(exchange_pair.from_token),
        to_token_id: exchange_pair.to_token.id,
        to_token: TokenSerializer.serialize(exchange_pair.to_token),
        rate: exchange_pair.rate,
        created_at: DateFormatter.to_iso8601(exchange_pair.inserted_at),
        updated_at: DateFormatter.to_iso8601(exchange_pair.updated_at),
        opposite_exchange_pair_id: opposite_pair.id,
        opposite_exchange_pair: %{
          object: "exchange_pair",
          id: opposite_pair.id,
          name: ExchangePair.get_name(opposite_pair),
          from_token_id: opposite_pair.from_token.id,
          from_token: TokenSerializer.serialize(opposite_pair.from_token),
          to_token_id: opposite_pair.to_token.id,
          to_token: TokenSerializer.serialize(opposite_pair.to_token),
          rate: opposite_pair.rate,
          default_exchange_wallet_address: exchange_pair.default_exchange_wallet_address,
          allow_end_user_exchanges: exchange_pair.allow_end_user_exchanges,
          created_at: DateFormatter.to_iso8601(opposite_pair.inserted_at),
          updated_at: DateFormatter.to_iso8601(opposite_pair.updated_at),
          deleted_at: nil
        },
        default_exchange_wallet_address: exchange_pair.default_exchange_wallet_address,
        allow_end_user_exchanges: exchange_pair.allow_end_user_exchanges,
        deleted_at: nil
      }

      assert ExchangePairSerializer.serialize(exchange_pair) == expected
    end

    test "serializes an exchange pair paginator into a list object" do
      exchange_pair1 = :exchange_pair |> insert() |> ExchangePairGate.add_opposite_pair()
      exchange_pair2 = :exchange_pair |> insert() |> ExchangePairGate.add_opposite_pair()

      paginator = %Paginator{
        data: [exchange_pair1, exchange_pair2],
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
            object: "exchange_pair",
            id: exchange_pair1.id,
            name: ExchangePair.get_name(exchange_pair1),
            from_token_id: exchange_pair1.from_token.id,
            from_token: TokenSerializer.serialize(exchange_pair1.from_token),
            to_token_id: exchange_pair1.to_token.id,
            to_token: TokenSerializer.serialize(exchange_pair1.to_token),
            rate: exchange_pair1.rate,
            created_at: DateFormatter.to_iso8601(exchange_pair1.inserted_at),
            updated_at: DateFormatter.to_iso8601(exchange_pair1.updated_at),
            opposite_exchange_pair_id: nil,
            opposite_exchange_pair: nil,
            default_exchange_wallet_address: exchange_pair1.default_exchange_wallet_address,
            allow_end_user_exchanges: exchange_pair1.allow_end_user_exchanges,
            deleted_at: nil
          },
          %{
            object: "exchange_pair",
            id: exchange_pair2.id,
            name: ExchangePair.get_name(exchange_pair2),
            from_token_id: exchange_pair2.from_token.id,
            from_token: TokenSerializer.serialize(exchange_pair2.from_token),
            to_token_id: exchange_pair2.to_token.id,
            to_token: TokenSerializer.serialize(exchange_pair2.to_token),
            rate: exchange_pair2.rate,
            created_at: DateFormatter.to_iso8601(exchange_pair2.inserted_at),
            updated_at: DateFormatter.to_iso8601(exchange_pair2.updated_at),
            opposite_exchange_pair_id: nil,
            opposite_exchange_pair: nil,
            default_exchange_wallet_address: exchange_pair2.default_exchange_wallet_address,
            allow_end_user_exchanges: exchange_pair2.allow_end_user_exchanges,
            deleted_at: nil
          }
        ],
        pagination: %{
          current_page: 9,
          per_page: 7,
          is_first_page: false,
          is_last_page: true
        }
      }

      assert ExchangePairSerializer.serialize(paginator) == expected
    end

    test "serializes to nil if the exchange pair is nil" do
      assert ExchangePairSerializer.serialize(nil) == nil
    end

    test "serializes to nil if the exchange pair is not loaded" do
      assert ExchangePairSerializer.serialize(%NotLoaded{}) == nil
    end

    test "serializes an empty exchange pair paginator into a list object" do
      paginator = %Paginator{
        data: [],
        pagination: %{
          current_page: 1,
          per_page: 10,
          is_first_page: true,
          is_last_page: true
        }
      }

      expected = %{
        object: "list",
        data: [],
        pagination: %{
          current_page: 1,
          per_page: 10,
          is_first_page: true,
          is_last_page: true
        }
      }

      assert ExchangePairSerializer.serialize(paginator) == expected
    end
  end
end
