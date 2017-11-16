defmodule KuberaDB.MintedTokenTest do
  use KuberaDB.SchemaCase
  alias KuberaDB.MintedToken

  describe "MintedToken factory" do
    test_has_valid_factory MintedToken

    test "saves the encrypted metadata" do
      {_, minted_token} =
        :minted_token
        |> params_for(metadata: %{something: "cool"})
        |> MintedToken.insert

      {:ok, results} = SQL.query(Repo, "SELECT metadata FROM minted_token", [])
      row = Enum.at(results.rows, 0)
      assert <<"SBX", 1, _::binary>> = Enum.at(row, 0)
      assert minted_token.metadata == %{"something" => "cool"}
    end
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

    test "saves the encrypted metadata" do
      {_, minted_token} =
        :minted_token
        |> params_for(metadata: %{something: "cool"})
        |> MintedToken.insert

      {:ok, results} = SQL.query(Repo, "SELECT metadata FROM minted_token", [])
      row = Enum.at(results.rows, 0)
      assert <<"SBX", 1, _::binary>> = Enum.at(row, 0)
      assert minted_token.metadata == %{"something" => "cool"}
    end

    test "inserts a balance for the minted token" do
      {res, minted_token} =
        MintedToken.insert(params_for(:minted_token))
      MintedToken.get_master_balance(minted_token)

      assert res == :ok
      minted_token =
        minted_token.symbol
        |> MintedToken.get()
        |> Repo.preload([:balances])

      assert length(minted_token.balances) == 1
    end
  end

  describe "all/0" do
    test "returns all existing minted tokens" do
      assert length(MintedToken.all) == 0

      MintedToken.insert(params_for(:minted_token))
      MintedToken.insert(params_for(:minted_token))
      MintedToken.insert(params_for(:minted_token))

      assert length(MintedToken.all) == 3
    end
  end

  describe "get/1" do
    test "returns an existing minted token using a symbol" do
      MintedToken.insert(params_for(:minted_token, %{symbol: "sym"}))

      token = MintedToken.get("sym")
      assert token.symbol == "sym"
    end

    test "returns nil if the minted token does not exist" do
      token = MintedToken.get("unknown")
      assert token == nil
    end
  end

  describe "get_main_balance/1" do
    test "returns the first balance" do
      {:ok, inserted} = MintedToken.insert(params_for(:minted_token))
      balance = MintedToken.get_master_balance(inserted)

      minted_token =
        inserted.symbol
        |> MintedToken.get()
        |> Repo.preload([:balances])

      assert balance != nil
      assert balance == Enum.at(minted_token.balances, 0)
    end

    test "make sure only 1 master balance is created at most" do
      {:ok, inserted} = MintedToken.insert(params_for(:minted_token))
      balance_1 = MintedToken.get_master_balance(inserted)
      balance_2 = MintedToken.get_master_balance(inserted)
      assert balance_1 == balance_2
    end
  end
end
