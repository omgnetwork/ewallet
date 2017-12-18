defmodule KuberaDB.MembershipTest do
  use KuberaDB.SchemaCase
  alias KuberaDB.{Membership, Repo}

  describe "Membership factory" do
    test_has_valid_factory Membership
  end

  describe "Membership.insert/1" do
    test_insert_generate_timestamps Membership

    test "inserts a membership with account, user and role successfully" do
      account = insert(:account)
      user = insert(:user)
      role = insert(:role)

      {res, membership} = Membership.insert(%{
        account_id: account.id,
        user_id: user.id,
        role_id: role.id
      })

      assert res == :ok

      membership = Repo.preload(membership, [:account, :user, :role])
      assert membership.account.id == account.id
      assert membership.user.id == user.id
      assert membership.role.id == role.id
    end
  end
end
