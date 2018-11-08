defmodule EWallet.Web.MatchAllQueryTest do
  use EWallet.DBCase
  import Ecto.Query
  import EWalletDB.Factory
  alias EWallet.Web.MatchAllQuery
  alias EWalletDB.{Repo, Token, User}

  defp on_all(dynamic, schema) do
    schema
    |> from(where: ^dynamic)
    |> Repo.all()
  end

  defp contains?(records, target) do
    Enum.any?(records, fn r -> r.id == target.id end)
  end

  describe "do_filter/5 with uuid field type" do
    test "supports 'eq' comparator" do
      user_1 = insert(:user)
      user_2 = insert(:user)
      user_3 = insert(:user)

      result =
        true
        |> MatchAllQuery.do_filter(:uuid, :uuid, "eq", user_2.uuid)
        |> on_all(User)

      refute contains?(result, user_1)
      assert contains?(result, user_2)
      refute contains?(result, user_3)
    end

    test "supports 'neq' comparator" do
      user_1 = insert(:user)
      user_2 = insert(:user)
      user_3 = insert(:user)

      result =
        true
        |> MatchAllQuery.do_filter(:uuid, :uuid, "neq", user_2.uuid)
        |> on_all(User)

      assert contains?(result, user_1)
      refute contains?(result, user_2)
      assert contains?(result, user_3)
    end

    test "supports 'contains' comparator" do
      user_1 = insert(:user)
      user_2 = insert(:user)
      user_3 = insert(:user)
      partial_uuid = String.slice(user_3.uuid, 5..15)

      result =
        true
        |> MatchAllQuery.do_filter(:uuid, :uuid, "contains", partial_uuid)
        |> on_all(User)

      refute contains?(result, user_1)
      refute contains?(result, user_2)
      assert contains?(result, user_3)
    end

    test "supports 'starts_with' comparator" do
      user_1 = insert(:user)
      user_2 = insert(:user)
      user_3 = insert(:user)
      uuid_head = String.slice(user_1.uuid, 0..10)

      result =
        true
        |> MatchAllQuery.do_filter(:uuid, :uuid, "starts_with", uuid_head)
        |> on_all(User)

      assert contains?(result, user_1)
      refute contains?(result, user_2)
      refute contains?(result, user_3)
    end
  end

  describe "do_filter/5 with 'eq' comparator" do
    test "matches a boolean field with a boolean value" do
      user_1 = insert(:user, is_admin: false)
      user_2 = insert(:user, is_admin: true)

      result =
        true
        |> MatchAllQuery.do_filter(:is_admin, :nil, "eq", true)
        |> on_all(User)

      refute contains?(result, user_1)
      assert contains?(result, user_2)
    end

    test "matches a boolean field with a string value" do
      user_1 = insert(:user, is_admin: false)
      user_2 = insert(:user, is_admin: true)

      result =
        true
        |> MatchAllQuery.do_filter(:is_admin, :nil, "eq", "false")
        |> on_all(User)

      assert contains?(result, user_1)
      refute contains?(result, user_2)
    end

    test "matches a string field with a string value" do
      user_1 = insert(:user, username: "user_one")
      user_2 = insert(:user, username: "user_two")

      result =
        true
        |> MatchAllQuery.do_filter(:username, :nil, "eq", "user_two")
        |> on_all(User)

      refute contains?(result, user_1)
      assert contains?(result, user_2)
    end

    test "matches a numeric field with a numeric value" do
      token_1 = insert(:token, subunit_to_unit: 100)
      token_2 = insert(:token, subunit_to_unit: 100000)

      result =
        true
        |> MatchAllQuery.do_filter(:subunit_to_unit, :nil, "eq", 100000)
        |> on_all(Token)

      refute contains?(result, token_1)
      assert contains?(result, token_2)
    end
  end

  describe "do_filter/5 with 'neq' comparator" do
    test "matches a boolean field with a boolean value" do
      user_1 = insert(:user, is_admin: false)
      user_2 = insert(:user, is_admin: true)

      result =
        true
        |> MatchAllQuery.do_filter(:is_admin, :nil, "neq", true)
        |> on_all(User)

      assert contains?(result, user_1)
      refute contains?(result, user_2)
    end

    test "matches a boolean field with a string value" do
      user_1 = insert(:user, is_admin: false)
      user_2 = insert(:user, is_admin: true)

      result =
        true
        |> MatchAllQuery.do_filter(:is_admin, :nil, "neq", "false")
        |> on_all(User)

      refute contains?(result, user_1)
      assert contains?(result, user_2)
    end

    test "matches a string field with a string value" do
      user_1 = insert(:user, username: "user_one")
      user_2 = insert(:user, username: "user_two")

      result =
        true
        |> MatchAllQuery.do_filter(:username, :nil, "neq", "user_two")
        |> on_all(User)

      assert contains?(result, user_1)
      refute contains?(result, user_2)
    end

    test "matches a numeric field with a numeric value" do
      token_1 = insert(:token, subunit_to_unit: 100)
      token_2 = insert(:token, subunit_to_unit: 100000)

      result =
        true
        |> MatchAllQuery.do_filter(:subunit_to_unit, :nil, "neq", 100000)
        |> on_all(Token)

      assert contains?(result, token_1)
      refute contains?(result, token_2)
    end
  end

  describe "do_filter/5 with 'gt' comparator" do
    test "matches a boolean field with a boolean value" do
      user_1 = insert(:user, is_admin: false)
      user_2 = insert(:user, is_admin: true)

      result =
        true
        |> MatchAllQuery.do_filter(:is_admin, :nil, "gt", false)
        |> on_all(User)

      refute contains?(result, user_1)
      assert contains?(result, user_2)
    end

    test "matches a string field with a string value" do
      user_1 = insert(:user, username: "aaaaa")
      user_2 = insert(:user, username: "bbbbb")

      result =
        true
        |> MatchAllQuery.do_filter(:username, :nil, "gt", "aaaaa")
        |> on_all(User)

      refute contains?(result, user_1)
      assert contains?(result, user_2)
    end

    test "matches a numeric field with a numeric value" do
      token_1 = insert(:token, subunit_to_unit: 100)
      token_2 = insert(:token, subunit_to_unit: 100000)

      result =
        true
        |> MatchAllQuery.do_filter(:subunit_to_unit, :nil, "gt", 100)
        |> on_all(Token)

      refute contains?(result, token_1)
      assert contains?(result, token_2)
    end
  end

  describe "do_filter/5 with 'gte' comparator" do
    test "matches a boolean field with a boolean value" do
      user_1 = insert(:user, is_admin: false)
      user_2 = insert(:user, is_admin: true)

      result =
        true
        |> MatchAllQuery.do_filter(:is_admin, :nil, "gte", true)
        |> on_all(User)

      refute contains?(result, user_1)
      assert contains?(result, user_2)
    end

    test "matches a string field with a string value" do
      user_1 = insert(:user, username: "aaaaa")
      user_2 = insert(:user, username: "bbbbb")

      result =
        true
        |> MatchAllQuery.do_filter(:username, :nil, "gte", "bbbbb")
        |> on_all(User)

      refute contains?(result, user_1)
      assert contains?(result, user_2)
    end

    test "matches a numeric field with a numeric value" do
      token_1 = insert(:token, subunit_to_unit: 100)
      token_2 = insert(:token, subunit_to_unit: 100000)

      result =
        true
        |> MatchAllQuery.do_filter(:subunit_to_unit, :nil, "gte", 100000)
        |> on_all(Token)

      refute contains?(result, token_1)
      assert contains?(result, token_2)
    end
  end

  describe "do_filter/5 with 'lt' comparator" do
    test "matches a boolean field with a boolean value" do
      user_1 = insert(:user, is_admin: false)
      user_2 = insert(:user, is_admin: true)

      result =
        true
        |> MatchAllQuery.do_filter(:is_admin, :nil, "lt", true)
        |> on_all(User)

      assert contains?(result, user_1)
      refute contains?(result, user_2)
    end

    test "matches a string field with a string value" do
      user_1 = insert(:user, username: "aaaaa")
      user_2 = insert(:user, username: "bbbbb")

      result =
        true
        |> MatchAllQuery.do_filter(:username, :nil, "lt", "bbbbb")
        |> on_all(User)

      assert contains?(result, user_1)
      refute contains?(result, user_2)
    end

    test "matches a numeric field with a numeric value" do
      token_1 = insert(:token, subunit_to_unit: 100)
      token_2 = insert(:token, subunit_to_unit: 100000)

      result =
        true
        |> MatchAllQuery.do_filter(:subunit_to_unit, :nil, "lt", 100000)
        |> on_all(Token)

      assert contains?(result, token_1)
      refute contains?(result, token_2)
    end
  end

  describe "do_filter/5 with 'lte' comparator" do
    test "matches a boolean field with a boolean value" do
      user_1 = insert(:user, is_admin: false)
      user_2 = insert(:user, is_admin: true)

      result =
        true
        |> MatchAllQuery.do_filter(:is_admin, :nil, "lte", false)
        |> on_all(User)

      assert contains?(result, user_1)
      refute contains?(result, user_2)
    end

    test "matches a string field with a string value" do
      user_1 = insert(:user, username: "aaaaa")
      user_2 = insert(:user, username: "bbbbb")

      result =
        true
        |> MatchAllQuery.do_filter(:username, :nil, "lte", "aaaaa")
        |> on_all(User)

      assert contains?(result, user_1)
      refute contains?(result, user_2)
    end

    test "matches a numeric field with a numeric value" do
      token_1 = insert(:token, subunit_to_unit: 100)
      token_2 = insert(:token, subunit_to_unit: 100000)

      result =
        true
        |> MatchAllQuery.do_filter(:subunit_to_unit, :nil, "lte", 100)
        |> on_all(Token)

      assert contains?(result, token_1)
      refute contains?(result, token_2)
    end
  end

  describe "do_filter/5 with 'contains' comparator" do
    test "matches a string field with a string value" do
      user_1 = insert(:user, username: "aaaaabbbbb")
      user_2 = insert(:user, username: "bbbbbaaaaa")

      result =
        true
        |> MatchAllQuery.do_filter(:username, :nil, "contains", "ba")
        |> on_all(User)

      refute contains?(result, user_1)
      assert contains?(result, user_2)
    end
  end

  describe "do_filter/5 with 'starts_with' comparator" do
    test "matches a string field with a string value" do
      user_1 = insert(:user, username: "aaaaabbbbb")
      user_2 = insert(:user, username: "bbbbbaaaaa")

      result =
        true
        |> MatchAllQuery.do_filter(:username, :nil, "starts_with", "bbb")
        |> on_all(User)

      refute contains?(result, user_1)
      assert contains?(result, user_2)
    end
  end
end
