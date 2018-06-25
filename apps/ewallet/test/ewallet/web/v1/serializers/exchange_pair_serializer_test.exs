defmodule EWallet.Web.V1.ExchangePairSerializerTest do
  use EWallet.Web.SerializerCase, :v1
  alias Ecto.Association.NotLoaded
  alias EWallet.Web.V1.{ExchangePairSerializer, TokenSerializer}
  alias EWallet.Web.{Paginator, Date}

  describe "serialize/1" do
    test "serializes an exchange pair into V1 response format" do
      exchange_pair = insert(:exchange_pair)

      expected = %{
        object: "exchange_pair",
        id: exchange_pair.id,
        name: exchange_pair.name,
        from_token_id: exchange_pair.from_token.id,
        from_token: TokenSerializer.serialize(exchange_pair.from_token),
        to_token_id: exchange_pair.to_token.id,
        to_token: TokenSerializer.serialize(exchange_pair.to_token),
        rate: exchange_pair.rate,
        reversible: exchange_pair.reversible,
        created_at: Date.to_iso8601(exchange_pair.inserted_at),
        updated_at: Date.to_iso8601(exchange_pair.updated_at)
      }

      assert ExchangePairSerializer.serialize(exchange_pair) == expected
    end

    test "serializes an exchange pair paginator into a list object" do
      exchange_pair1 = insert(:exchange_pair)
      exchange_pair2 = insert(:exchange_pair)

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
            name: exchange_pair1.name,
            from_token_id: exchange_pair1.from_token.id,
            from_token: TokenSerializer.serialize(exchange_pair1.from_token),
            to_token_id: exchange_pair1.to_token.id,
            to_token: TokenSerializer.serialize(exchange_pair1.to_token),
            rate: exchange_pair1.rate,
            reversible: exchange_pair1.reversible,
            created_at: Date.to_iso8601(exchange_pair1.inserted_at),
            updated_at: Date.to_iso8601(exchange_pair1.updated_at)
          },
          %{
            object: "exchange_pair",
            id: exchange_pair2.id,
            name: exchange_pair2.name,
            from_token_id: exchange_pair2.from_token.id,
            from_token: TokenSerializer.serialize(exchange_pair2.from_token),
            to_token_id: exchange_pair2.to_token.id,
            to_token: TokenSerializer.serialize(exchange_pair2.to_token),
            rate: exchange_pair2.rate,
            reversible: exchange_pair2.reversible,
            created_at: Date.to_iso8601(exchange_pair2.inserted_at),
            updated_at: Date.to_iso8601(exchange_pair2.updated_at)
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
