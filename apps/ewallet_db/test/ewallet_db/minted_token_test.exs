defmodule EWalletDB.MintedTokenTest do
  use EWalletDB.SchemaCase
  alias EWalletDB.MintedToken

  describe "MintedToken factory" do
    test_has_valid_factory MintedToken
    test_encrypted_map_field MintedToken, "minted_token", :metadata
  end

  describe "insert/1" do
    test_insert_generate_uuid MintedToken, :id
    test_insert_generate_timestamps MintedToken
    test_insert_prevent_blank MintedToken, :symbol
    test_insert_prevent_blank MintedToken, :name
    test_insert_prevent_blank MintedToken, :subunit_to_unit
    test_insert_prevent_duplicate MintedToken, :symbol
    test_insert_prevent_duplicate MintedToken, :iso_code
    test_insert_prevent_duplicate MintedToken, :name

    test "generates a friendly_id" do
      {:ok, minted_token} =
        :minted_token |> params_for(friendly_id: nil, symbol: "OMG") |> MintedToken.insert

      assert "OMG:" <> uuid = minted_token.friendly_id
      assert minted_token.id == uuid
      assert String.match?(uuid, ~r/[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}/)
    end

    test "does not regenerate a friendly_id if already there" do
      {:ok, minted_token} =
        :minted_token |> params_for(friendly_id: "OMG:123") |> MintedToken.insert

      assert minted_token.friendly_id == "OMG:123"
    end
  end

  describe "all/0" do
    test "returns all existing minted tokens" do
      assert length(MintedToken.all) == 0

      :minted_token |> params_for() |> MintedToken.insert
      :minted_token |> params_for() |> MintedToken.insert
      :minted_token |> params_for() |> MintedToken.insert

      assert length(MintedToken.all) == 3
    end
  end

  describe "get/1" do
    test "returns an existing minted token using a symbol" do
      {:ok, inserted} =
        :minted_token |> params_for(friendly_id: nil, symbol: "sym") |> MintedToken.insert

      token = MintedToken.get(inserted.friendly_id)
      assert "sym:" <> _ = token.friendly_id
      assert token.symbol == "sym"
    end

    test "returns nil if the minted token does not exist" do
      token = MintedToken.get("unknown")
      assert token == nil
    end
  end
end
