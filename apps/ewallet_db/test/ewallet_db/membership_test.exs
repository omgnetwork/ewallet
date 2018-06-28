defmodule EWalletDB.MembershipTest do
  use EWalletDB.SchemaCase
  alias EWalletDB.{Membership, User, Repo, Account}

  describe "Membership factory" do
    # Not using `test_has_valid_factory/1` macro here because `Membership.insert/1` is private.
    # So we need to do `Repo.insert/1` directly to test the factory.
    test "produces valid params and inserts successfully" do
      {res, membership} = :membership |> build() |> Repo.insert()

      assert res == :ok
      assert %Membership{} = membership
    end
  end

  defp prepare_membership do
    user = insert(:user)
    account = insert(:account)
    role = insert(:role, %{name: "some_role"})
    membership = insert(:membership, %{user: user, account: account, role: role})

    {membership, user, account, role}
  end

  describe "Membership.get_by_user_and_account/2" do
    test "returns a list of memberships associated with the given user and account" do
      {membership, user, account, _} = prepare_membership()
      result = Membership.get_by_user_and_account(user, account)

      assert result.uuid == membership.uuid
    end
  end

  describe "Membership.all_by_user/1" do
    test "returns all memberships associated with the given user" do
      {membership, user, _, _} = prepare_membership()
      result = Membership.all_by_user(user)

      assert Enum.at(result, 0).uuid == membership.uuid
    end
  end

  describe "Membership.assign/3" do
    test "returns {:ok, membership} on successful assignment" do
      user = insert(:user)
      account = insert(:account)
      role = insert(:role, %{name: "some_role"})

      {res, membership} = Membership.assign(user, account, "some_role")

      assert res == :ok
      assert membership.user_uuid == user.uuid
      assert membership.account_uuid == account.uuid
      assert membership.role_uuid == role.uuid
    end

    test "re-assigns user to the new role if the user has an existing role on the account" do
      user = insert(:user)
      account = insert(:account)

      insert(:role, %{name: "old_role"})
      insert(:role, %{name: "new_role"})

      {:ok, _membership} = Membership.assign(user, account, "old_role")
      {:ok, _membership} = Membership.assign(user, account, "new_role")

      user = Repo.preload(user, :roles, force: true)
      assert User.get_roles(user) == ["new_role"]
    end

    test "returns {:error, :user_already_has_rights} when
          user has more powerful role in ancestor" do
      user = insert(:user)
      level_0 = Account.get_master_account()
      level_1 = insert(:account, parent: level_0)
      level_2 = insert(:account, parent: level_1)
      admin = insert(:role, name: "admin", priority: 0)
      viewer = insert(:role, name: "viewer", priority: 1)

      # We assign to the master account
      {:ok, inserted_membership} = Membership.assign(user, level_0, admin)

      # So we can't assign the role viewer here on a lower account
      {res, reason} = Membership.assign(user, level_2, viewer)

      assert res == :error
      assert reason == :user_already_has_rights

      memberships = Membership.all_by_user(user)
      assert length(memberships) == 1
      membership = Enum.at(memberships, 0)
      assert membership.uuid == inserted_membership.uuid
    end

    test "returns {:ok, membership} when user has less powerful role in ancestor" do
      user = insert(:user)
      level_0 = Account.get_master_account()
      level_1 = insert(:account, parent: level_0)
      level_2 = insert(:account, parent: level_1)
      admin = insert(:role, name: "admin", priority: 0)
      viewer = insert(:role, name: "viewer", priority: 1)

      {:ok, _membership} = Membership.assign(user, level_0, viewer)
      {res, membership} = Membership.assign(user, level_2, admin)

      assert res == :ok
      assert membership.user_uuid == user.uuid
      assert membership.account_uuid == level_2.uuid
      assert membership.role_uuid == admin.uuid

      assert length(Membership.all_by_user(user)) == 2
    end

    test "returns {:error, :user_already_has_rights} when the user has two more
          powerful roles in ancestors" do
      user = insert(:user)
      level_0 = Account.get_master_account()
      level_1 = insert(:account, parent: level_0)
      level_2 = insert(:account, parent: level_1)
      level_3 = insert(:account, parent: level_2)
      admin = insert(:role, name: "admin", priority: 0)
      viewer = insert(:role, name: "viewer", priority: 1)
      grunt = insert(:role, name: "grunt", priority: 2)

      {:ok, _membership} = Membership.assign(user, level_0, viewer)
      {:ok, _membership} = Membership.assign(user, level_2, admin)
      {res, reason} = Membership.assign(user, level_3, grunt)

      assert res == :error
      assert reason == :user_already_has_rights
    end

    test "returns {:ok, membership} when the user has two less powerful roles
          in ancestors" do
      user = insert(:user)
      level_0 = Account.get_master_account()
      level_1 = insert(:account, parent: level_0)
      level_2 = insert(:account, parent: level_1)
      level_3 = insert(:account, parent: level_2)
      admin = insert(:role, name: "admin", priority: 0)
      viewer = insert(:role, name: "viewer", priority: 1)
      grunt = insert(:role, name: "grunt", priority: 2)

      {:ok, _membership} = Membership.assign(user, level_0, grunt)
      {:ok, _membership} = Membership.assign(user, level_2, viewer)
      {res, membership} = Membership.assign(user, level_3, admin)

      assert res == :ok
      assert membership.user_uuid == user.uuid
      assert membership.account_uuid == level_3.uuid
      assert membership.role_uuid == admin.uuid

      assert length(Membership.all_by_user(user)) == 3
    end

    test "returns {:ok, membership} when user has more powerful role
          in descendant" do
      user = insert(:user)
      level_0 = Account.get_master_account()
      level_1 = insert(:account, parent: level_0)
      level_2 = insert(:account, parent: level_1)
      admin = insert(:role, name: "admin", priority: 0)
      viewer = insert(:role, name: "viewer", priority: 1)

      {:ok, _membership} = Membership.assign(user, level_2, admin)
      {res, membership} = Membership.assign(user, level_0, viewer)

      assert res == :ok
      assert membership.user_uuid == user.uuid
      assert membership.account_uuid == level_0.uuid
      assert membership.role_uuid == viewer.uuid

      assert length(Membership.all_by_user(user)) == 2
    end

    test "removes and re-assigns the user when user has less powerful
          role in descendant" do
      user = insert(:user)
      level_0 = Account.get_master_account()
      level_1 = insert(:account, parent: level_0)
      level_2 = insert(:account, parent: level_1)
      admin = insert(:role, name: "admin", priority: 0)
      viewer = insert(:role, name: "viewer", priority: 1)

      {:ok, inserted_membership} = Membership.assign(user, level_2, viewer)
      {res, membership} = Membership.assign(user, level_0, admin)

      assert res == :ok
      assert membership.user_uuid == user.uuid
      assert membership.account_uuid == level_0.uuid
      assert membership.role_uuid == admin.uuid
      assert membership.uuid != inserted_membership.uuid

      assert length(Membership.all_by_user(user)) == 1
    end

    test "removes and re-assigns the user when user has same role in descendant" do
      user = insert(:user)
      level_0 = Account.get_master_account()
      level_1 = insert(:account, parent: level_0)
      level_2 = insert(:account, parent: level_1)
      admin = insert(:role, name: "admin", priority: 0)

      {:ok, inserted_membership} = Membership.assign(user, level_2, admin)
      {res, membership} = Membership.assign(user, level_0, admin)

      assert res == :ok
      assert membership.user_uuid == user.uuid
      assert membership.account_uuid == level_0.uuid
      assert membership.role_uuid == admin.uuid
      assert membership.uuid != inserted_membership.uuid

      assert length(Membership.all_by_user(user)) == 1
    end

    test "assigns the user if he has a membership in another branch" do
      user = insert(:user)
      level_0 = Account.get_master_account()

      level_1_1 = insert(:account, parent: level_0)
      level_2_1 = insert(:account, parent: level_1_1)

      level_1_2 = insert(:account, parent: level_0)
      level_2_2 = insert(:account, parent: level_1_2)

      admin = insert(:role, name: "admin", priority: 0)

      {:ok, inserted_membership} = Membership.assign(user, level_2_1, admin)
      {res, membership} = Membership.assign(user, level_2_2, admin)

      assert res == :ok
      assert membership.user_uuid == user.uuid
      assert membership.account_uuid == level_2_2.uuid
      assert membership.role_uuid == admin.uuid
      assert membership.uuid != inserted_membership.uuid

      assert length(Membership.all_by_user(user)) == 2
    end

    test "unassign and reassigns if the user had memberships in 2 branches" do
      user = insert(:user)
      level_0 = Account.get_master_account()

      level_1_1 = insert(:account, parent: level_0)
      level_2_1 = insert(:account, parent: level_1_1)

      level_1_2 = insert(:account, parent: level_0)
      level_2_2 = insert(:account, parent: level_1_2)

      admin = insert(:role, name: "admin", priority: 0)

      {:ok, _inserted_membership_1} = Membership.assign(user, level_2_1, admin)
      {:ok, _inserted_membership_2} = Membership.assign(user, level_2_2, admin)
      {res, membership} = Membership.assign(user, level_0, admin)

      assert res == :ok
      assert membership.user_uuid == user.uuid
      assert membership.account_uuid == level_0.uuid
      assert membership.role_uuid == admin.uuid

      assert length(Membership.all_by_user(user)) == 1
    end

    test "returns {:error} on successful assignment" do
      user = insert(:user)
      account = insert(:account)
      role = insert(:role, %{name: "some_role"})

      {res, membership} = Membership.assign(user, account, "some_role")

      assert res == :ok
      assert membership.user_uuid == user.uuid
      assert membership.account_uuid == account.uuid
      assert membership.role_uuid == role.uuid
    end

    test "returns {:error, :role_not_found} if the given role does not exist" do
      user = insert(:user)
      account = insert(:account)

      {res, reason} = Membership.assign(user, account, "missing_role")
      assert res == :error
      assert reason == :role_not_found
    end

    test "prevents a user from being assigned if he is already an ancestor" do
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
      user = insert(:user)
      account = insert(:account)

      assert Membership.unassign(user, account) == {:error, :membership_not_found}
    end
  end
end
