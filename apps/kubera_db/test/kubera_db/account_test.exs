defmodule KuberaDB.AccountTest do
  use ExUnit.Case
  import KuberaDB.Factory
  alias KuberaDB.{Repo, Account}
  alias Ecto.Adapters.SQL.Sandbox

  setup do
    :ok = Sandbox.checkout(Repo)
  end

  describe "factory" do
    test "has a valid factory" do
      {res, _account} = Account.insert(params_for(:account))
      assert res == :ok
    end
  end

  describe "insert/1" do
    test "generates a UUID in place of a regular ID" do
      {res, account} = :account |> params_for |> Account.insert

      assert res == :ok
      assert String.match?(account.id,
        ~r/[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}/)
    end

    test "generates the inserted_at and updated_at values" do
      {res, account} = :account |> params_for |> Account.insert

      assert res == :ok
      assert account.inserted_at != nil
      assert account.updated_at != nil
    end

    test "prevents creation of an account with a blank name" do
      {result, changeset} =
        :account
        |> params_for(%{name: ""})
        |> Account.insert

      assert result == :error
      assert changeset.errors ==
        [name: {"can't be blank", [validation: :required]}]
    end

    test "returns error if an account with same name already exists" do
      {_result, _account} =
        :account
        |> params_for(%{name: "same_name"})
        |> Account.insert

      {result, changeset} =
        :account
        |> params_for(%{name: "same_name"})
        |> Account.insert

      assert result == :error
      assert changeset.errors == [name: {"has already been taken", []}]
    end
  end
end
