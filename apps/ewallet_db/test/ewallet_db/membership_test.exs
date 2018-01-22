defmodule EWalletDB.MembershipTest do
  use EWalletDB.SchemaCase
  alias EWalletDB.{Membership, User, Repo}

  describe "Membership factory" do
    # Not using `test_has_valid_factory/1` macro here because `Membership.insert/1` is private.
    # So we need to do `Repo.insert/1` directly to test the factory.
    test "produces valid params and inserts successfully" do
      {res, membership} = :membership |> build() |> Repo.insert()

      assert res == :ok
      assert %Membership{} = membership
    end
  end

  describe "Membership.assign/3" do
    test "returns {:ok, membership} on successful assignment" do
      user    = insert(:user)
      account = insert(:account)
      role    = insert(:role, %{name: "some_role"})

      {res, membership} = Membership.assign(user, account, "some_role")

      assert res == :ok
      assert membership.user_id == user.id
      assert membership.account_id == account.id
      assert membership.role_id == role.id
    end

    test "re-assigns user to the new role if the user has an existing role on the account" do
      user    = insert(:user)
      account = insert(:account)

      insert(:role, %{name: "old_role"})
      insert(:role, %{name: "new_role"})

      {:ok, _membership} = Membership.assign(user, account, "old_role")
      {:ok, _membership}  = Membership.assign(user, account, "new_role")

      user = Repo.preload(user, :roles, force: true)
      assert User.get_roles(user) == ["new_role"]
    end

    test "returns {:error, :role_not_found} if the given role does not exist" do
      user    = insert(:user)
      account = insert(:account)

      {res, reason} = Membership.assign(user, account, "missing_role")
      assert res == :error
      assert reason == :role_not_found
    end
  end

  describe "Membership.unassign/2" do
    test "returns {:ok, membership} when unassigned successfully" do
      {user, account} = insert_user_with_role("some_role")
      assert User.get_roles(user) == ["some_role"]

      {:ok, _} = Membership.unassign(user, account)
      assert User.get_roles(user) == []
    end

    test "returns {:error, :membership_not_found} if the user is not assigned to the account" do
      user    = insert(:user)
      account = insert(:account)

      assert Membership.unassign(user, account) == {:error, :membership_not_found}
    end
  end
end
