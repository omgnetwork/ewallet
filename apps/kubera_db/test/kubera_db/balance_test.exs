defmodule KuberaDB.BalanceTest do
  use ExUnit.Case
  import KuberaDB.Factory
  alias KuberaDB.{Repo, Balance}
  alias Ecto.Adapters.SQL.Sandbox

  setup do
    :ok = Sandbox.checkout(Repo)
  end

  test "has a valid factory" do
    attrs = params_for(:balance)
    changeset = Balance.changeset(%Balance{}, attrs)
    assert changeset.valid?
  end

  describe "changeset/1" do
    test "validates address can't be blank" do
      changeset =
        Balance.changeset(%Balance{}, params_for(:balance, %{address: nil}))

      refute changeset.valid?
      assert changeset.errors ==
        [address: {"can't be blank", [validation: :required]}]
    end

    test "validates user and minted_token can't both be blank" do
      changeset =
        Balance.changeset(%Balance{}, params_for(:balance, %{
          user: nil, minted_token: nil
        }))

      refute changeset.valid?
      assert changeset.errors ==
        [{[:account_id, :minted_token_id, :user_id], {"can't all be blank", []}}]
    end

    test "validates user and minted_token can't both be present" do
      changeset =
        Balance.changeset(%Balance{}, params_for(:balance, %{
          user: insert(:user), minted_token: insert(:minted_token)
        }))

      refute changeset.valid?
      assert changeset.errors ==
        [{[:account_id, :minted_token_id, :user_id], {"only one must be present", []}}]
    end
  end

  describe "insert/1" do
    test "generates a UUID in place of a regular integer ID" do
      {res, balance} = :balance |> params_for |> Balance.insert

      assert res == :ok
      assert String.match?(balance.id,
        ~r/[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}/)
    end

    test "generates an address as UUID if the address is not given" do
      {res, balance} =
        :balance |> params_for(%{address: nil}) |> Balance.insert

      assert res == :ok
      assert String.match?(balance.address,
        ~r/[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}/)
    end

    test "generates the inserted_at and updated_at values" do
      {res, balance} = :balance |> params_for |> Balance.insert

      assert res == :ok
      assert balance.inserted_at != nil
      assert balance.updated_at != nil
    end

    test "allows insert if provided a user without minted_token" do
      {res, _balance} =
        :balance
        |> params_for(%{user: insert(:user), minted_token: nil})
        |> Balance.insert

      assert res == :ok
    end

    test "allows insert if provided a minted_token without user" do
      {res, _balance} =
        :balance
        |> params_for(%{minted_token: insert(:minted_token), user: nil})
        |> Balance.insert

      assert res == :ok
    end

    test "insert with the specified address if given" do
      {res, balance} =
        :balance
        |> params_for(%{address: "the_address"})
        |> Balance.insert

      assert res == :ok
      assert balance.address == "the_address"
    end

    test "prevents creation of a balance with a blank address" do
      {result, changeset} =
        :balance
        |> params_for(%{address: ""})
        |> Balance.insert

      assert result == :error
      assert changeset.errors ==
        [address: {"can't be blank", [validation: :required]}]
    end

    test "prevents creation of a balance without a user nor minted token" do
      {result, changeset} =
        :balance
        |> params_for(%{user: nil, minted_token: nil})
        |> Balance.insert

      assert result == :error
      assert changeset.errors ==
        [{[:account_id, :minted_token_id, :user_id], {"can't all be blank", []}}]
    end

    test "prevents creation of a balance with both a user and minted token" do
      params = %{user: insert(:user), minted_token: insert(:minted_token)}
      {result, changeset} = :balance |> params_for(params) |> Balance.insert

      assert result == :error
      assert changeset.errors ==
        [{[:account_id, :minted_token_id, :user_id], {"only one must be present", []}}]
    end

    test "returns error if balance with same address already exists" do
      {_result, _balance} =
        :balance
        |> params_for(%{address: "same_address"})
        |> Balance.insert

      {result, changeset} =
        :balance
        |> params_for(%{address: "same_address"})
        |> Balance.insert

      assert result == :error
      assert changeset.errors == [address: {"has already been taken", []}]
    end
  end

  describe "get/1" do
    test "returns an existing balance using an address" do
      :balance
      |> params_for(%{address: "balance_address1234"})
      |> Balance.insert

      balance = Balance.get("balance_address1234")
      assert balance.address == "balance_address1234"
    end

    test "returns nil if the balance address does not exist" do
      assert Balance.get("nonexisting_address") == nil
    end
  end
end
