defmodule EWallet.Web.V1.TokenSerializerTest do
  use EWallet.Web.SerializerCase, :v1
  alias Ecto.Association.NotLoaded
  alias EWallet.Web.V1.TokenSerializer

  describe "serialize/1 for single token" do
    test "serializes into correct V1 token format" do
      token = build(:token)

      expected = %{
        object: "token",
        id: token.id,
        symbol: token.symbol,
        name: token.name,
        subunit_to_unit: token.subunit_to_unit,
        metadata: token.metadata,
        encrypted_metadata: token.encrypted_metadata,
        created_at: token.inserted_at,
        updated_at: token.updated_at
      }

      assert TokenSerializer.serialize(token) == expected
    end

    test "serializes to nil if the token is not loaded" do
      assert TokenSerializer.serialize(%NotLoaded{}) == nil
    end
  end

  describe "serialize/1 for tokens list" do
    test "serialize into list of V1 token" do
      token1 = build(:token)
      token2 = build(:token)
      tokens = [token1, token2]

      expected = [
        %{
          object: "token",
          id: token1.id,
          symbol: token1.symbol,
          name: token1.name,
          subunit_to_unit: token1.subunit_to_unit,
          metadata: token1.metadata,
          encrypted_metadata: token1.encrypted_metadata,
          created_at: token1.inserted_at,
          updated_at: token1.updated_at
        },
        %{
          object: "token",
          id: token2.id,
          symbol: token2.symbol,
          name: token2.name,
          subunit_to_unit: token2.subunit_to_unit,
          metadata: token2.metadata,
          encrypted_metadata: token2.encrypted_metadata,
          created_at: token2.inserted_at,
          updated_at: token2.updated_at
        }
      ]

      assert TokenSerializer.serialize(tokens) == expected
    end
  end
end
