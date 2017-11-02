defmodule KuberaDB.MintedTokenTest do
  use ExUnit.Case
  import KuberaDB.Factory
  alias KuberaDB.{MintedToken, Repo}
  alias Ecto.Adapters.SQL.Sandbox

  setup do
    :ok = Sandbox.checkout(Repo)
  end

  test "has a valid factory" do
    changeset = MintedToken.changeset(%MintedToken{}, params_for(:minted_token))
    assert changeset.valid?
  end

  describe "changeset/2" do
    test "validates symbol can't be blank" do
      changeset = MintedToken.changeset(%MintedToken{},
        params_for(:minted_token, %{symbol: ""}))

      refute changeset.valid?
      assert changeset.errors ==
        [symbol: {"can't be blank", [validation: :required]}]
    end

    test "validates name can't be blank" do
      changeset = MintedToken.changeset(%MintedToken{},
        params_for(:minted_token, %{name: ""}))

      refute changeset.valid?
      assert changeset.errors ==
        [name: {"can't be blank", [validation: :required]}]
    end

    test "validates subunit_to_unit can't be blank" do
      changeset = MintedToken.changeset(%MintedToken{},
        params_for(:minted_token, %{subunit_to_unit: nil}))

      refute changeset.valid?
      assert changeset.errors ==
        [subunit_to_unit: {"can't be blank", [validation: :required]}]
    end
  end

  describe "insert/1" do
    test "generates a UUID in place of a regular ID" do
      {res, minted_token} =
        MintedToken.insert(params_for(:minted_token))

      assert res == :ok
      assert String.match?(minted_token.id,
        ~r/[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}/)
    end

    test "generates the inserted_at and updated_at values" do
      {res, minted_token} =
        MintedToken.insert(params_for(:minted_token))

      assert res == :ok
      assert minted_token.inserted_at != nil
      assert minted_token.updated_at != nil
    end

    test "prevents creation of a minted token without a symbol" do
      {result, changeset} =
        MintedToken.insert(params_for(:minted_token, %{symbol: ""}))

      assert result == :error
      assert changeset.errors ==
        [symbol: {"can't be blank", [validation: :required]}]
    end

    test "prevents creation of a minted token with existing symbol" do
      {result_1, _changeset_1} =
        MintedToken.insert(params_for(:minted_token, %{symbol: "SYM"}))

      {result_2, changeset_2} =
        MintedToken.insert(params_for(:minted_token, %{symbol: "SYM"}))

      assert result_1 == :ok
      assert result_2 == :error
      assert changeset_2.errors == [symbol: {"has already been taken", []}]
    end

    test "prevents creation of a minted token with existing iso_code" do
      {result_1, _changeset_1} =
        MintedToken.insert(params_for(:minted_token, %{iso_code: "SYM"}))

      {result_2, changeset_2} =
        MintedToken.insert(params_for(:minted_token, %{iso_code: "SYM"}))

      assert result_1 == :ok
      assert result_2 == :error
      assert changeset_2.errors == [iso_code: {"has already been taken", []}]
    end

    test "prevents creation of a minted token with existing name" do
      {result_1, _changeset_1} =
        MintedToken.insert(params_for(:minted_token, %{name: "Same Token Name"}))

      {result_2, changeset_2} =
        MintedToken.insert(params_for(:minted_token, %{name: "Same Token Name"}))

      assert result_1 == :ok
      assert result_2 == :error
      assert changeset_2.errors == [name: {"has already been taken", []}]
    end

    test "inserts a balance for the minted token" do
      {res, minted_token} =
        MintedToken.insert(params_for(:minted_token))
      MintedToken.get_main_balance(minted_token)

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
      balance = MintedToken.get_main_balance(inserted)

      minted_token =
        inserted.symbol
        |> MintedToken.get()
        |> Repo.preload([:balances])

      assert balance != nil
      assert balance == Enum.at(minted_token.balances, 0)
    end
  end
end
