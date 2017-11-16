defmodule KuberaDB.BalanceTest do
  use KuberaDB.SchemaCase
  alias KuberaDB.Balance

  describe "Balance factory" do
    test_has_valid_factory Balance

    test "saves the encrypted metadata" do
      {_, balance} =
        :balance
        |> params_for(metadata: %{something: "cool"})
        |> Balance.insert

      {:ok, results} = SQL.query(Repo, "SELECT metadata FROM balance", [])
      row = Enum.at(results.rows, 0)
      assert <<"SBX", 1, _::binary>> = Enum.at(row, 0)

      balance = Repo.get(Balance, balance.id)
      assert balance.metadata == %{"something" => "cool"}
    end
  end

  describe "Balance.insert/1" do
    test_insert_ok Balance, :address, "an_address"

    test_insert_generate_uuid Balance, :id
    test_insert_generate_uuid Balance, :address
    test_insert_generate_timestamps Balance

    test_insert_prevent_blank Balance, :address
    test_insert_prevent_all_blank Balance, [:account, :minted_token, :genesis, :user]
    test_insert_prevent_duplicate Balance, :address

    test "saves the encrypted metadata" do
      {_, balance} =
        :balance
        |> params_for(metadata: %{something: "cool"})
        |> Balance.insert

      {:ok, results} = SQL.query(Repo, "SELECT metadata FROM balance", [])
      row = Enum.at(results.rows, 0)
      assert <<"SBX", 1, _::binary>> = Enum.at(row, 0)

      balance = Repo.get(Balance, balance.id)
      assert balance.metadata == %{"something" => "cool"}
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

    test "prevents creation of a balance with both a user and minted token" do
      params = %{user: insert(:user), minted_token: insert(:minted_token)}
      {result, changeset} = :balance |> params_for(params) |> Balance.insert

      assert result == :error
      assert changeset.errors ==
        [{[:account_id, :minted_token_id, :user_id, :genesis],
         {"only one must be present", []}}]
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

  describe "genesis/0" do
    test "inserts the genesis address if not existing" do
      assert Balance.get("genesis") == nil
      {:ok, genesis} = Balance.genesis()
      assert Balance.get("genesis") == genesis
    end

    test "returns the existing genesis address if present" do
      {:ok, inserted_genesis} = Balance.genesis()
      {:ok, genesis} = Balance.genesis()
      assert inserted_genesis == genesis
    end
  end
end
