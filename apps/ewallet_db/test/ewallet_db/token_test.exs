defmodule EWalletDB.TokenTest do
  use EWalletDB.SchemaCase
  alias EWalletDB.Token

  describe "Token factory" do
    test_has_valid_factory(Token)
    test_encrypted_map_field(Token, "token", :encrypted_metadata)
  end

  describe "insert/1" do
    test_insert_generate_uuid(Token, :uuid)
    test_insert_generate_timestamps(Token)
    test_insert_prevent_blank(Token, :symbol)
    test_insert_prevent_blank(Token, :name)
    test_insert_prevent_blank(Token, :subunit_to_unit)
    test_insert_prevent_duplicate(Token, :symbol)
    test_insert_prevent_duplicate(Token, :iso_code)
    test_insert_prevent_duplicate(Token, :name)
    test_default_metadata_fields(Token, "token")

    test "generates an id with the schema prefix and token symbol" do
      {:ok, token} =
        :token |> params_for(id: nil, symbol: "OMG") |> Token.insert()

      assert "tok_OMG_" <> ulid = token.id
      # A ULID has 26 characters
      assert String.length(ulid) == 26
    end

    test "allow subunit to be set between 0 and 1.0e18" do
      {:ok, token} =
        :token |> params_for(subunit_to_unit: 1.0e18) |> Token.insert()

      assert token.subunit_to_unit == 1_000_000_000_000_000_000
    end

    test "fails to insert when subunit is equal to 1.0e19" do
      {:error, error} =
        :token |> params_for(subunit_to_unit: 1.0e19) |> Token.insert()

      assert error.errors == [
               subunit_to_unit:
                 {"must be less than or equal to %{number}",
                  [validation: :number, number: 1.0e18]}
             ]
    end

    test "fails to insert when subunit is inferior to 0" do
      {:error, error} = :token |> params_for(subunit_to_unit: -2) |> Token.insert()

      assert error.errors == [
               subunit_to_unit:
                 {"must be greater than %{number}", [validation: :number, number: 0]}
             ]
    end

    test "fails to insert when subunit is superior to 1.0e18" do
      {:error, error} =
        :token |> params_for(subunit_to_unit: 1.0e82) |> Token.insert()

      assert error.errors == [
               subunit_to_unit:
                 {"must be less than or equal to %{number}",
                  [validation: :number, number: 1.0e18]}
             ]
    end
  end

  describe "all/0" do
    test "returns all existing tokens" do
      assert Enum.empty?(Token.all())

      :token |> params_for() |> Token.insert()
      :token |> params_for() |> Token.insert()
      :token |> params_for() |> Token.insert()

      assert length(Token.all()) == 3
    end
  end

  describe "get/1" do
    test "returns an existing token using a symbol" do
      {:ok, inserted} =
        :token |> params_for(id: nil, symbol: "sym") |> Token.insert()

      token = Token.get(inserted.id)
      assert "tok_sym_" <> _ = token.id
      assert token.symbol == "sym"
    end

    test "returns nil if the token does not exist" do
      token = Token.get("unknown")
      assert token == nil
    end
  end
end
