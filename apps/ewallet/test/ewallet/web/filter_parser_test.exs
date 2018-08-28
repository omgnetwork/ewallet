defmodule EWallet.Web.FilterParserTest do
  use EWallet.DBCase
  import EWalletDB.Factory
  alias EWallet.Web.FilterParser
  alias EWalletDB.{Account, Transaction, Repo, User}

  describe "to_query/3" do
    test "filter for boolean true when given 'true' as value" do
      user_1 = insert(:user, is_admin: false)
      user_2 = insert(:user, is_admin: false)
      user_3 = insert(:user, is_admin: true)

      attrs = %{
        "filters" => [
          %{
            "field" => "is_admin",
            "comparator" => "eq",
            "value" => "true"
          }
        ]
      }

      query = FilterParser.to_query(User, attrs, [:is_admin])
      result = Repo.all(query)

      refute Enum.any?(result, fn user -> user.id == user_1.id end)
      refute Enum.any?(result, fn user -> user.id == user_2.id end)
      assert Enum.any?(result, fn user -> user.id == user_3.id end)
    end

    test "returns records filtered with 'eq'" do
      txn_1 = insert(:transaction, from_amount: 100)
      txn_2 = insert(:transaction, from_amount: 200)
      txn_3 = insert(:transaction, from_amount: 300)

      attrs = %{
        "filters" => [
          %{
            "field" => "from_amount",
            "comparator" => "eq",
            "value" => 100
          }
        ]
      }

      query = FilterParser.to_query(Transaction, attrs, [:from_amount])
      result = Repo.all(query)

      assert Enum.any?(result, fn txn -> txn.id == txn_1.id end)
      refute Enum.any?(result, fn txn -> txn.id == txn_2.id end)
      refute Enum.any?(result, fn txn -> txn.id == txn_3.id end)
    end

    test "returns records filtered with 'neq'" do
      txn_1 = insert(:transaction, from_amount: 100)
      txn_2 = insert(:transaction, from_amount: 200)
      txn_3 = insert(:transaction, from_amount: 300)

      attrs = %{
        "filters" => [
          %{
            "field" => "from_amount",
            "comparator" => "neq",
            "value" => 100
          }
        ]
      }

      query = FilterParser.to_query(Transaction, attrs, [:from_amount])
      result = Repo.all(query)

      refute Enum.any?(result, fn txn -> txn.id == txn_1.id end)
      assert Enum.any?(result, fn txn -> txn.id == txn_2.id end)
      assert Enum.any?(result, fn txn -> txn.id == txn_3.id end)
    end

    test "returns records filtered with 'gt'" do
      txn_1 = insert(:transaction, from_amount: 100)
      txn_2 = insert(:transaction, from_amount: 200)
      txn_3 = insert(:transaction, from_amount: 300)

      attrs = %{
        "filters" => [
          %{
            "field" => "from_amount",
            "comparator" => "gt",
            "value" => 100
          }
        ]
      }

      query = FilterParser.to_query(Transaction, attrs, [:from_amount])
      result = Repo.all(query)

      refute Enum.any?(result, fn txn -> txn.id == txn_1.id end)
      assert Enum.any?(result, fn txn -> txn.id == txn_2.id end)
      assert Enum.any?(result, fn txn -> txn.id == txn_3.id end)
    end

    test "returns records filtered with 'gte'" do
      txn_1 = insert(:transaction, from_amount: 100)
      txn_2 = insert(:transaction, from_amount: 200)
      txn_3 = insert(:transaction, from_amount: 300)

      attrs = %{
        "filters" => [
          %{
            "field" => "from_amount",
            "comparator" => "gte",
            "value" => 100
          }
        ]
      }

      query = FilterParser.to_query(Transaction, attrs, [:from_amount])
      result = Repo.all(query)

      assert Enum.any?(result, fn txn -> txn.id == txn_1.id end)
      assert Enum.any?(result, fn txn -> txn.id == txn_2.id end)
      assert Enum.any?(result, fn txn -> txn.id == txn_3.id end)
    end

    test "returns records filtered with 'lt'" do
      txn_1 = insert(:transaction, from_amount: 100)
      txn_2 = insert(:transaction, from_amount: 200)
      txn_3 = insert(:transaction, from_amount: 300)

      attrs = %{
        "filters" => [
          %{
            "field" => "from_amount",
            "comparator" => "lt",
            "value" => 200
          }
        ]
      }

      query = FilterParser.to_query(Transaction, attrs, [:from_amount])
      result = Repo.all(query)

      assert Enum.any?(result, fn txn -> txn.id == txn_1.id end)
      refute Enum.any?(result, fn txn -> txn.id == txn_2.id end)
      refute Enum.any?(result, fn txn -> txn.id == txn_3.id end)
    end

    test "returns records filtered with 'lte'" do
      txn_1 = insert(:transaction, from_amount: 100)
      txn_2 = insert(:transaction, from_amount: 200)
      txn_3 = insert(:transaction, from_amount: 300)

      attrs = %{
        "filters" => [
          %{
            "field" => "from_amount",
            "comparator" => "lte",
            "value" => 200
          }
        ]
      }

      query = FilterParser.to_query(Transaction, attrs, [:from_amount])
      result = Repo.all(query)

      assert Enum.any?(result, fn txn -> txn.id == txn_1.id end)
      assert Enum.any?(result, fn txn -> txn.id == txn_2.id end)
      refute Enum.any?(result, fn txn -> txn.id == txn_3.id end)
    end

    test "returns records filtered with 'contains'" do
      account_1 = insert(:account)
      account_2 = insert(:account, name: "Filter Parser Test 1")
      account_3 = insert(:account)

      attrs = %{
        "filters" => [
          %{
            "field" => "name",
            "comparator" => "contains",
            "value" => "er Parser"
          }
        ]
      }

      query = FilterParser.to_query(Account, attrs, [:name])
      result = Repo.all(query)

      refute Enum.any?(result, fn acc -> acc.id == account_1.id end)
      assert Enum.any?(result, fn acc -> acc.id == account_2.id end)
      refute Enum.any?(result, fn acc -> acc.id == account_3.id end)
    end

    test "returns error if a filter param is missing" do
      _txn = insert(:transaction, from_amount: 100)

      attrs = %{
        "filters" => [
          %{
            "field" => "from_amount",
            "comparator" => "eq"
            # "value" => txn.from_amount
          }
        ]
      }

      {res, code, params} = FilterParser.to_query(Transaction, attrs, [])

      assert res == :error
      assert code == :missing_filter_param
      assert params == %{"comparator" => "eq", "field" => "from_amount"}
    end

    test "returns error if filtering is not allowed on the field" do
      txn = insert(:transaction, from_amount: 100)

      attrs = %{
        "filters" => [
          %{
            "field" => "from_amount",
            "comparator" => "eq",
            "value" => txn.from_amount
          }
        ]
      }

      result = FilterParser.to_query(Transaction, attrs, [])

      assert result == {:error, :not_allowed, "from_amount"}
    end
  end
end
