defmodule AdminAPI.V1.MintedTokenSerializerTest do
  use AdminAPI.SerializerCase, :v1
  alias AdminAPI.V1.MintedTokenSerializer
  alias EWallet.Web.{Date, Paginator}

  describe "MintedToken.to_json/1" do
    test "serializes a minted token into V1 response format" do
      minted_token = insert(:minted_token)

      expected = %{
        object: "minted_token",
        id: minted_token.friendly_id,
        symbol: minted_token.symbol,
        name: minted_token.name,
        subunit_to_unit: minted_token.subunit_to_unit,
        created_at: Date.to_iso8601(minted_token.inserted_at),
        updated_at: Date.to_iso8601(minted_token.updated_at)
      }

      assert MintedTokenSerializer.to_json(minted_token) == expected
    end

    test "serializes a minted token paginator into a list object" do
      minted_token1 = insert(:minted_token)
      minted_token2 = insert(:minted_token)
      paginator = %Paginator{
        data: [minted_token1, minted_token2],
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
            object: "minted_token",
            id: minted_token1.friendly_id,
            symbol: minted_token1.symbol,
            name: minted_token1.name,
            subunit_to_unit: minted_token1.subunit_to_unit,
            created_at: Date.to_iso8601(minted_token1.inserted_at),
            updated_at: Date.to_iso8601(minted_token1.updated_at)
          },
          %{
            object: "minted_token",
            id: minted_token2.friendly_id,
            symbol: minted_token2.symbol,
            name: minted_token2.name,
            subunit_to_unit: minted_token2.subunit_to_unit,
            created_at: Date.to_iso8601(minted_token2.inserted_at),
            updated_at: Date.to_iso8601(minted_token2.updated_at)
          }
        ],
        pagination: %{
          current_page: 9,
          per_page: 7,
          is_first_page: false,
          is_last_page: true
        }
      }

      assert MintedTokenSerializer.to_json(paginator) == expected
    end
  end
end
