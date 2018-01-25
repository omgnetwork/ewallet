defmodule EWalletDB.UserQueryTest do
  use EWalletDB.SchemaCase
  alias EWalletDB.{User, UserQuery}

  describe "UserQuery.where_has_membership/1" do
    test "returns only admins" do
      account = insert(:account)
      role    = insert(:role, %{name: "some_role"})
      admin1  = insert(:admin, %{email: "admin1@omise.co"})
      admin2  = insert(:admin, %{email: "admin2@omise.co"})
      user    = insert(:user, %{email: "user1@omise.co"})

      insert(:membership, %{user: admin1, account: account, role: role})
      insert(:membership, %{user: admin2, account: account, role: role})

      result =
        User
        |> UserQuery.where_has_membership()
        |> Repo.all()

      assert Enum.count(result) == 2
      assert Enum.at(result, 0).email == admin1.email
      assert Enum.at(result, 1).email == admin2.email
      refute Enum.any?(result, fn(admin) -> admin.email == user.email end)
    end

    test "returns unique records" do
      account1 = insert(:account)
      account2 = insert(:account)
      admin    = insert(:admin, %{email: "admin1@omise.co"})
      role     = insert(:role, %{name: "some_role"})

      insert(:membership, %{user: admin, account: account1, role: role})
      insert(:membership, %{user: admin, account: account2, role: role})

      result =
        User
        |> UserQuery.where_has_membership()
        |> Repo.all()

      assert Enum.count(result) == 1
      assert Enum.at(result, 0).email == admin.email
    end

    test "uses `EWalletDB.User` if `queryable` is not given" do
      account = insert(:account)
      role    = insert(:role, %{name: "some_role"})
      admin   = insert(:admin, %{email: "admin@omise.co"})
      insert(:membership, %{user: admin, account: account, role: role})

      query = UserQuery.where_has_membership()
      result = Repo.all(query)

      assert Enum.count(result) == 1
    end
  end
end
