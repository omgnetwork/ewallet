defmodule EWalletAPI.V1.MintedTokenSerializerTest do
  use EWalletAPI.SerializerCase, :v1
  alias EWalletAPI.V1.MintedTokenSerializer

  describe "serialize/1 for single minted_token" do
    test "serializes into correct V1 minted_token format" do
      minted_token = build(:minted_token)

      expected = %{
        object: "minted_token",
        id: minted_token.friendly_id,
        symbol: minted_token.symbol,
        name: minted_token.name,
        subunit_to_unit: minted_token.subunit_to_unit,
        metadata: minted_token.metadata,
        encrypted_metadata: minted_token.encrypted_metadata
      }

      assert MintedTokenSerializer.serialize(minted_token) == expected
    end
  end

  describe "serialize/1 for minted_tokens list" do
    test "serialize into list of V1 minted_token" do
      token1 = build(:minted_token)
      token2 = build(:minted_token)
      minted_tokens = [token1, token2]

      expected = [
        %{
          object: "minted_token",
          id: token1.friendly_id,
          symbol: token1.symbol,
          name: token1.name,
          subunit_to_unit: token1.subunit_to_unit,
          metadata: token1.metadata,
          encrypted_metadata: token1.encrypted_metadata
        },
        %{
          object: "minted_token",
          id: token2.friendly_id,
          symbol: token2.symbol,
          name: token2.name,
          subunit_to_unit: token2.subunit_to_unit,
          metadata: token2.metadata,
          encrypted_metadata: token2.encrypted_metadata
        }
      ]

      assert MintedTokenSerializer.serialize(minted_tokens) == expected
    end
  end
end
