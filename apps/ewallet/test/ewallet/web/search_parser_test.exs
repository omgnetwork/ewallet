defmodule EWallet.Web.SearchParserTest do
  use EWallet.DBCase
  import EWalletDB.Factory
  alias EWallet.Web.SearchParser
  alias EWalletDB.{Repo, Account}

  defp prepare_test_accounts do
    account_1 = insert(:account, %{name: "Name Match 1", description: "Description missed 1"})
    account_2 = insert(:account, %{name: "Name Match 2", description: "Description missed 2"})
    account_3 = insert(:account, %{name: "Name Missed 1", description: "Description match 1"})
    account_4 = insert(:account, %{name: "Name Missed 2", description: "Description match 2"})

    [account_1, account_2, account_3, account_4]
  end

  describe "EWallet.Web.SearchParser.to_query/3 with search_term" do
    test "returns records that the given term matches exactly as tuple" do
      account = prepare_test_accounts() |> Enum.at(0)

      attrs = %{"search_term" => account.id}

      result =
        Account
        |> SearchParser.to_query(attrs, [:id, :name])
        |> Repo.all()

      assert Enum.count(result) == 1
      assert Enum.at(result, 0).name == "Name Match 1"
    end

    test "returns records that the given term matches exactly" do
      prepare_test_accounts()

      attrs = %{"search_term" => "Name Match 1"}

      result =
        Account
        |> SearchParser.to_query(attrs, [:name])
        |> Repo.all()

      assert Enum.count(result) == 1
      assert Enum.at(result, 0).name == "Name Match 1"
    end

    test "returns records that the given term matches partially" do
      prepare_test_accounts()

      attrs = %{"search_term" => "me Matc"}

      result =
        Account
        |> SearchParser.to_query(attrs, [:name])
        |> Repo.all()

      names = Enum.map(result, fn account -> account.name end)
      assert Enum.count(result) == 2
      assert Enum.member?(names, "Name Match 1")
      assert Enum.member?(names, "Name Match 2")
    end

    test "returns records that the given term matches case-insensitively" do
      prepare_test_accounts()

      attrs = %{"search_term" => "NAME MATCH"}

      result =
        Account
        |> SearchParser.to_query(attrs, [:name])
        |> Repo.all()

      names = Enum.map(result, fn account -> account.name end)
      assert Enum.count(names) == 2
      assert Enum.member?(names, "Name Match 1")
      assert Enum.member?(names, "Name Match 2")
    end

    test "returns records that the given term matches in different fields" do
      prepare_test_accounts()

      attrs = %{"search_term" => "match"}

      result =
        Account
        |> SearchParser.to_query(attrs, [:name, :description])
        |> Repo.all()

      assert Enum.count(result) == 4
    end

    test "does not return records that match outside the allowed search fields" do
      prepare_test_accounts()

      attrs = %{"search_term" => "Description match 1"}

      result =
        Account
        |> SearchParser.to_query(attrs, [:name])
        |> Repo.all()

      assert Enum.empty?(result)
    end

    test "returns original query if search_term is missing" do
      original = Account
      attrs = %{"wrong_attr" => "Name Match 1"}
      result = SearchParser.to_query(original, attrs, [:name])

      assert result == original
    end
  end

  describe "EWallet.Web.SearchParser.to_query/3 with search_terms" do
    test "returns records that the given term matches exactly as tuple" do
      account = prepare_test_accounts() |> Enum.at(0)

      attrs = %{"search_terms" => %{"id" => account.id}}

      result =
        Account
        |> SearchParser.to_query(attrs, [:id, :name])
        |> Repo.all()

      assert Enum.count(result) == 1
      assert Enum.at(result, 0).name == "Name Match 1"
    end

    test "returns records that the given term matches exactly" do
      prepare_test_accounts()

      attrs = %{"search_terms" => %{"name" => "Name Match 1"}}

      result =
        Account
        |> SearchParser.to_query(attrs, [:name])
        |> Repo.all()

      assert Enum.count(result) == 1
      assert Enum.at(result, 0).name == "Name Match 1"
    end

    test "returns records that the given term matches partially" do
      prepare_test_accounts()

      attrs = %{"search_terms" => %{"name" => "me Matc"}}

      result =
        Account
        |> SearchParser.to_query(attrs, [:name])
        |> Repo.all()

      assert Enum.count(result) == 2
      result = Enum.map(result, fn r -> r.name end)
      assert Enum.member?(result, "Name Match 1")
      assert Enum.member?(result, "Name Match 2")
    end

    test "returns records that the given term matches case-insensitively" do
      prepare_test_accounts()

      attrs = %{"search_terms" => %{"name" => "NAME MATCH"}}

      result =
        Account
        |> SearchParser.to_query(attrs, [:name])
        |> Repo.all()

      names = Enum.map(result, fn account -> account.name end)
      assert Enum.count(names) == 2
      assert Enum.member?(names, "Name Match 1")
      assert Enum.member?(names, "Name Match 2")
    end

    test "returns records that the given term matches in different fields" do
      prepare_test_accounts()

      attrs = %{"search_terms" => %{"name" => "match"}}

      result =
        Account
        |> SearchParser.to_query(attrs, [:name, :description])
        |> Repo.all()

      assert Enum.count(result) == 2
    end

    test "does not return records that match outside the allowed search fields" do
      prepare_test_accounts()

      attrs = %{"search_terms" => %{"name" => "Description match 1"}}

      result =
        Account
        |> SearchParser.to_query(attrs, [:name])
        |> Repo.all()

      assert Enum.empty?(result)
    end

    test "returns records mapped to a different field" do
      account = prepare_test_accounts() |> Enum.at(0)

      attrs = %{"search_terms" => %{"mapped_id" => account.id}}

      result =
        Account
        |> SearchParser.to_query(attrs, [:id], %{"mapped_id" => "id"})
        |> Repo.all()

      assert Enum.count(result) == 1
      assert Enum.at(result, 0).name == account.name
    end

    test "returns original query if search_terms is missing" do
      original = Account
      attrs = %{"search_terms" => %{"wrong_attr" => "Name Match 1"}}
      result = SearchParser.to_query(original, attrs, [:name])

      assert result == original
    end
  end
end
