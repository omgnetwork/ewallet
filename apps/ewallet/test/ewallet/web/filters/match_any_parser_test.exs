defmodule EWallet.Web.MatchAnyParserTest do
  use EWallet.DBCase
  import EWalletDB.Factory
  alias EWallet.Web.{MatchAnyParser, Preloader}
  alias EWalletDB.{Account, Repo, Transaction, User}

  describe "to_query/3" do
    test "filter for boolean true when given 'true' as value" do
      user_1 = insert(:user, is_admin: false)
      user_2 = insert(:user, is_admin: false)
      user_3 = insert(:user, is_admin: true)

      attrs = %{
        "match_any" => [
          %{
            "field" => "is_admin",
            "comparator" => "eq",
            "value" => "true"
          }
        ]
      }

      query = MatchAnyParser.to_query(User, attrs, [:is_admin])
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
        "match_any" => [
          %{
            "field" => "from_amount",
            "comparator" => "eq",
            "value" => 100
          }
        ]
      }

      query = MatchAnyParser.to_query(Transaction, attrs, [:from_amount])
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
        "match_any" => [
          %{
            "field" => "from_amount",
            "comparator" => "neq",
            "value" => 100
          }
        ]
      }

      query = MatchAnyParser.to_query(Transaction, attrs, [:from_amount])
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
        "match_any" => [
          %{
            "field" => "from_amount",
            "comparator" => "gt",
            "value" => 100
          }
        ]
      }

      query = MatchAnyParser.to_query(Transaction, attrs, [:from_amount])
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
        "match_any" => [
          %{
            "field" => "from_amount",
            "comparator" => "gte",
            "value" => 100
          }
        ]
      }

      query = MatchAnyParser.to_query(Transaction, attrs, [:from_amount])
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
        "match_any" => [
          %{
            "field" => "from_amount",
            "comparator" => "lt",
            "value" => 200
          }
        ]
      }

      query = MatchAnyParser.to_query(Transaction, attrs, [:from_amount])
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
        "match_any" => [
          %{
            "field" => "from_amount",
            "comparator" => "lte",
            "value" => 200
          }
        ]
      }

      query = MatchAnyParser.to_query(Transaction, attrs, [:from_amount])
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
        "match_any" => [
          %{
            "field" => "name",
            "comparator" => "contains",
            "value" => "er Parser"
          }
        ]
      }

      query = MatchAnyParser.to_query(Account, attrs, [:name])
      result = Repo.all(query)

      refute Enum.any?(result, fn acc -> acc.id == account_1.id end)
      assert Enum.any?(result, fn acc -> acc.id == account_2.id end)
      refute Enum.any?(result, fn acc -> acc.id == account_3.id end)
    end

    test "returns records filtered with 'starts_with'" do
      account_1 = insert(:account, name: "Some Parser Test")
      account_2 = insert(:account, name: "Beginning Filter Parser")
      account_3 = insert(:account, name: "Middle Filter Parser")

      attrs = %{
        "match_any" => [
          %{
            "field" => "name",
            "comparator" => "starts_with",
            "value" => "Begin"
          }
        ]
      }

      query = MatchAnyParser.to_query(Account, attrs, [:name])
      result = Repo.all(query)

      refute Enum.any?(result, fn acc -> acc.id == account_1.id end)
      assert Enum.any?(result, fn acc -> acc.id == account_2.id end)
      refute Enum.any?(result, fn acc -> acc.id == account_3.id end)
    end
  end

  describe "to_query/3 with nested fields" do
    test "filter for boolean true when given 'true' as value" do
      whitelist = [from_user: [:is_admin]]

      txn_1 = insert(:transaction)
      txn_2 = insert(:transaction)
      txn_3 = insert(:transaction)

      {:ok, txn_2} = Preloader.preload_one(txn_2, :from_user)
      {:ok, _user} = User.set_admin(txn_2.from_user, true)

      attrs = %{
        "match_any" => [
          %{
            "field" => "from_user.is_admin",
            "comparator" => "eq",
            "value" => "true"
          }
        ]
      }

      query = MatchAnyParser.to_query(Transaction, attrs, whitelist)
      result = Repo.all(query)

      refute Enum.any?(result, fn txn -> txn.id == txn_1.id end)
      assert Enum.any?(result, fn txn -> txn.id == txn_2.id end)
      refute Enum.any?(result, fn txn -> txn.id == txn_3.id end)
    end

    test "returns records filtered with 'eq'" do
      whitelist = [from_user: [:username]]

      txn_1 = insert(:transaction)
      txn_2 = insert(:transaction)
      txn_3 = insert(:transaction)

      {:ok, txn_2} = Preloader.preload_one(txn_2, :from_user)

      attrs = %{
        "match_any" => [
          %{
            "field" => "from_user.username",
            "comparator" => "eq",
            "value" => txn_2.from_user.username
          }
        ]
      }

      query = MatchAnyParser.to_query(Transaction, attrs, whitelist)
      result = Repo.all(query)

      refute Enum.any?(result, fn txn -> txn.id == txn_1.id end)
      assert Enum.any?(result, fn txn -> txn.id == txn_2.id end)
      refute Enum.any?(result, fn txn -> txn.id == txn_3.id end)
    end

    test "returns records filtered with 'neq'" do
      whitelist = [from_user: [:username]]

      txn_1 = insert(:transaction)
      txn_2 = insert(:transaction)
      txn_3 = insert(:transaction)

      {:ok, txn_2} = Preloader.preload_one(txn_2, :from_user)

      attrs = %{
        "match_any" => [
          %{
            "field" => "from_user.username",
            "comparator" => "neq",
            "value" => txn_2.from_user.username
          }
        ]
      }

      query = MatchAnyParser.to_query(Transaction, attrs, whitelist)
      result = Repo.all(query)

      assert Enum.any?(result, fn txn -> txn.id == txn_1.id end)
      refute Enum.any?(result, fn txn -> txn.id == txn_2.id end)
      assert Enum.any?(result, fn txn -> txn.id == txn_3.id end)
    end

    test "returns records filtered with 'gt'" do
      whitelist = [from_user: [:inserted_at]]

      txn_1 = insert(:transaction)
      txn_2 = insert(:transaction)
      txn_3 = insert(:transaction)

      {:ok, txn_2} = Preloader.preload_one(txn_2, :from_user)

      attrs = %{
        "match_any" => [
          %{
            "field" => "from_user.inserted_at",
            "comparator" => "gt",
            "value" => txn_2.from_user.inserted_at
          }
        ]
      }

      query = MatchAnyParser.to_query(Transaction, attrs, whitelist)
      result = Repo.all(query)

      refute Enum.any?(result, fn txn -> txn.id == txn_1.id end)
      refute Enum.any?(result, fn txn -> txn.id == txn_2.id end)
      assert Enum.any?(result, fn txn -> txn.id == txn_3.id end)
    end

    test "returns records filtered with 'gte'" do
      whitelist = [from_user: [:inserted_at]]

      txn_1 = insert(:transaction)
      txn_2 = insert(:transaction)
      txn_3 = insert(:transaction)

      {:ok, txn_2} = Preloader.preload_one(txn_2, :from_user)

      attrs = %{
        "match_any" => [
          %{
            "field" => "from_user.inserted_at",
            "comparator" => "gte",
            "value" => txn_2.from_user.inserted_at
          }
        ]
      }

      query = MatchAnyParser.to_query(Transaction, attrs, whitelist)
      result = Repo.all(query)

      refute Enum.any?(result, fn txn -> txn.id == txn_1.id end)
      assert Enum.any?(result, fn txn -> txn.id == txn_2.id end)
      assert Enum.any?(result, fn txn -> txn.id == txn_3.id end)
    end

    test "returns records filtered with 'lt'" do
      whitelist = [from_user: [:inserted_at]]

      txn_1 = insert(:transaction)
      txn_2 = insert(:transaction)
      txn_3 = insert(:transaction)

      {:ok, txn_2} = Preloader.preload_one(txn_2, :from_user)

      attrs = %{
        "match_any" => [
          %{
            "field" => "from_user.inserted_at",
            "comparator" => "lt",
            "value" => txn_2.from_user.inserted_at
          }
        ]
      }

      query = MatchAnyParser.to_query(Transaction, attrs, whitelist)
      result = Repo.all(query)

      assert Enum.any?(result, fn txn -> txn.id == txn_1.id end)
      refute Enum.any?(result, fn txn -> txn.id == txn_2.id end)
      refute Enum.any?(result, fn txn -> txn.id == txn_3.id end)
    end

    test "returns records filtered with 'lte'" do
      whitelist = [from_user: [:inserted_at]]

      txn_1 = insert(:transaction)
      txn_2 = insert(:transaction)
      txn_3 = insert(:transaction)

      {:ok, txn_2} = Preloader.preload_one(txn_2, :from_user)

      attrs = %{
        "match_any" => [
          %{
            "field" => "from_user.inserted_at",
            "comparator" => "lte",
            "value" => txn_2.from_user.inserted_at
          }
        ]
      }

      query = MatchAnyParser.to_query(Transaction, attrs, whitelist)
      result = Repo.all(query)

      assert Enum.any?(result, fn txn -> txn.id == txn_1.id end)
      assert Enum.any?(result, fn txn -> txn.id == txn_2.id end)
      refute Enum.any?(result, fn txn -> txn.id == txn_3.id end)
    end

    test "returns records filtered with 'contains'" do
      whitelist = [from_token: [:name]]

      txn_1 = insert(:transaction)
      txn_2 = insert(:transaction, from_token: insert(:token, name: "partial_match_token"))
      txn_3 = insert(:transaction)

      attrs = %{
        "match_any" => [
          %{
            "field" => "from_token.name",
            "comparator" => "contains",
            "value" => "ial_match_"
          }
        ]
      }

      query = MatchAnyParser.to_query(Transaction, attrs, whitelist)
      result = Repo.all(query)

      refute Enum.any?(result, fn txn -> txn.id == txn_1.id end)
      assert Enum.any?(result, fn txn -> txn.id == txn_2.id end)
      refute Enum.any?(result, fn txn -> txn.id == txn_3.id end)
    end

    test "returns records filtered with 'starts_with'" do
      whitelist = [from_token: [:name]]

      txn_1 = insert(:transaction, from_token: insert(:token, name: "not_beginning_match_1"))
      txn_2 = insert(:transaction, from_token: insert(:token, name: "not_beginning_match_2"))
      txn_3 = insert(:transaction, from_token: insert(:token, name: "beginning_match"))

      attrs = %{
        "match_any" => [
          %{
            "field" => "from_token.name",
            "comparator" => "starts_with",
            "value" => "begin"
          }
        ]
      }

      query = MatchAnyParser.to_query(Transaction, attrs, whitelist)
      result = Repo.all(query)

      refute Enum.any?(result, fn txn -> txn.id == txn_1.id end)
      refute Enum.any?(result, fn txn -> txn.id == txn_2.id end)
      assert Enum.any?(result, fn txn -> txn.id == txn_3.id end)
    end
  end

  describe "to_query/3 with multiple conditions" do
    test "returns records that match at least one condition" do
      txn_1 = insert(:transaction, status: "pending")
      txn_2 = insert(:transaction, status: "confirmed")
      txn_3 = insert(:transaction, status: "approved")
      txn_4 = insert(:transaction, status: "rejected")

      attrs = %{
        "match_any" => [
          %{
            "field" => "status",
            "comparator" => "eq",
            "value" => "pending"
          },
          %{
            "field" => "status",
            "comparator" => "eq",
            "value" => "rejected"
          }
        ]
      }

      query = MatchAnyParser.to_query(Transaction, attrs, [:status])
      result = Repo.all(query)

      assert Enum.any?(result, fn txn -> txn.id == txn_1.id end)
      refute Enum.any?(result, fn txn -> txn.id == txn_2.id end)
      refute Enum.any?(result, fn txn -> txn.id == txn_3.id end)
      assert Enum.any?(result, fn txn -> txn.id == txn_4.id end)
    end
  end
end
