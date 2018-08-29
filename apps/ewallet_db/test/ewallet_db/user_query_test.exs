defmodule EWalletDB.UserQueryTest do
  use EWalletDB.SchemaCase
  alias EWalletDB.{User, UserQuery}

  describe "where_has_membership/1" do
    test "returns only users with memberships" do
      user1 = insert(:admin, %{email: "user1@example.com"})
      user2 = insert(:admin, %{email: "user2@example.com"})
      user3 = insert(:user, %{email: "user3@example.com"})

      insert(:membership, %{user: user1})
      insert(:membership, %{user: user2})

      result =
        User
        |> UserQuery.where_has_membership()
        |> Repo.all()

      assert Enum.count(result) == 2
      assert Enum.any?(result, fn admin -> admin.email == user1.email end)
      assert Enum.any?(result, fn admin -> admin.email == user2.email end)
      refute Enum.any?(result, fn admin -> admin.email == user3.email end)
    end

    test "returns unique records" do
      user = insert(:admin, %{email: "multiple.memberships@example.com"})

      insert(:membership, %{user: user})
      insert(:membership, %{user: user})

      result =
        User
        |> UserQuery.where_has_membership()
        |> Repo.all()

      assert Enum.count(result) == 1
      assert Enum.at(result, 0).email == user.email
    end

    test "uses `EWalletDB.User` if `queryable` is not given" do
      user = insert(:admin, %{email: "default.user@example.com"})
      insert(:membership, %{user: user})

      query = UserQuery.where_has_membership()
      result = Repo.all(query)

      assert Enum.count(result) == 1
    end
  end

  describe "where_end_user/1" do
    test "returns end users only" do
      _user = insert(:user, %{email: "where.end.user.user1@example.com"})
      _user = insert(:user, %{email: "where.end.user.user2@example.com"})

      result =
        User
        |> UserQuery.where_end_user()
        |> Repo.all()

      assert Enum.all?(result, fn user -> User.admin?(user) == false end)
    end

    test "returns end users with provider_user_id" do
      inserted = insert(:user, %{email: "provider.user.id@example.com", provider_user_id: "1234"})

      result =
        User
        |> UserQuery.where_end_user()
        |> Repo.all()

      assert Enum.any?(result, fn user -> user.id == inserted.id end)
    end

    test "returns end users without provider_user_id" do
      inserted = insert(:user, %{email: "no.provider.user.id@example.com", provider_user_id: nil})

      result =
        User
        |> UserQuery.where_end_user()
        |> Repo.all()

      assert Enum.any?(result, fn user -> user.id == inserted.id end)
    end

    test "does not return the admin" do
      admin = insert(:admin, %{email: "where.end.user.admin@example.com"})
      _membership = insert(:membership, %{user: admin})

      result =
        User
        |> UserQuery.where_end_user()
        |> Repo.all()

      refute Enum.any?(result, fn user -> user.id == admin.id end)
    end

    test "does not return the admin even if the admin has provider_user_id" do
      admin = insert(:admin, %{email: "provider.user.id@example.com", provider_user_id: "123"})
      _membership = insert(:membership, %{user: admin})

      result =
        User
        |> UserQuery.where_end_user()
        |> Repo.all()

      refute Enum.any?(result, fn user -> user.id == admin.id end)
    end
  end
end
