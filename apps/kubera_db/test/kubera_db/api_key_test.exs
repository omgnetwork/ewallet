defmodule KuberaDB.APIKeyTest do
  use ExUnit.Case
  import KuberaDB.Factory
  alias KuberaDB.{Repo, APIKey}
  alias Ecto.Adapters.SQL.Sandbox

  setup do
    :ok = Sandbox.checkout(Repo)
  end

  test "has a valid factory" do
    changeset = APIKey.changeset(%APIKey{}, params_for(:api_key))
    assert changeset.valid?
  end

  describe "changeset/2" do
    test "validates key can't be blank" do
      changeset =
        %APIKey{}
        |> APIKey.changeset(params_for(:api_key, %{key: nil}))

      refute changeset.valid?
      assert changeset.errors ==
        [key: {"can't be blank", [validation: :required]}]
    end

    test "validates account can't be blank" do
      changeset =
        %APIKey{}
        |> APIKey.changeset(params_for(:api_key, %{account: nil}))

      refute changeset.valid?
      assert changeset.errors ==
        [account_id: {"can't be blank", [validation: :required]}]
    end
  end

  describe "insert/1" do
    test "generates a UUID in place of a regular ID" do
      {res, api_key} = :api_key |> params_for |> APIKey.insert

      assert res == :ok
      assert String.match?(api_key.id,
        ~r/[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}/)
    end

    test "generates the inserted_at and updated_at values" do
      {res, api_key} = :api_key |> params_for |> APIKey.insert

      assert res == :ok
      assert api_key.inserted_at != nil
      assert api_key.updated_at != nil
    end

    test "prevents creation without account specified" do
      {result, changeset} =
        :api_key
        |> params_for(%{account: ""})
        |> APIKey.insert

      assert result == :error
      assert changeset.errors ==
        [account_id: {"can't be blank", [validation: :required]}]
    end

    test "generates key with length == 43" do
      {result, api_key} =
        :api_key
        |> params_for(%{key: nil})
        |> APIKey.insert

      assert result == :ok
      assert String.length(api_key.key) == 43
    end

    test "allows multiple API keys for each account" do
      account = insert(:account)

      {result1, api_key_1} =
        :api_key
        |> params_for(%{account: account})
        |> APIKey.insert

      {result2, api_key_2} =
        :api_key
        |> params_for(%{account: account})
        |> APIKey.insert

      api_key_count =
        account
        |> Ecto.assoc(:api_keys)
        |> Repo.aggregate(:count, :id)

      assert result1 == :ok
      assert api_key_1.account_id == account.id
      assert result2 == :ok
      assert api_key_2.account_id == account.id
      assert api_key_count == 2
    end

    test "returns error if the same key already exists" do
      {_result, _api_key} =
        :api_key
        |> params_for(%{key: "same_key"})
        |> APIKey.insert

      {result, changeset} =
        :api_key
        |> params_for(%{key: "same_key"})
        |> APIKey.insert

      assert result == :error
      assert changeset.errors == [key: {"has already been taken", []}]
    end
  end

  describe "authenticate/1" do
    test "returns the associated account if exists" do
      account = insert(:account)

      :api_key
      |> params_for(%{key: "apikey123", account: account})
      |> APIKey.insert

      auth_account = APIKey.authenticate("apikey123")
      assert auth_account == account
    end

    test "returns false if API key does not exists" do
      :api_key
      |> params_for(%{key: "apikey123"})
      |> APIKey.insert

      assert APIKey.authenticate("unmatched") == false
    end

    test "returns false if API key is nil" do
      assert APIKey.authenticate(nil) == false
    end
  end
end
