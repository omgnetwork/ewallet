defmodule EWallet.Web.SearchParserTest do
  use EWallet.DBCase
  import EWalletDB.Factory
  alias EWallet.Web.SearchParser
  alias EWalletDB.{Repo, Account}

  defp prepare_test_accounts do
    insert(:account, %{name: "Name Match 1", description: "Description missed 1"})
    insert(:account, %{name: "Name Match 2", description: "Description missed 2"})
    insert(:account, %{name: "Name Missed 1", description: "Description match 1"})
    insert(:account, %{name: "Name Missed 2", description: "Description match 2"})
  end

  describe "EWallet.Web.SearchParser.to_query/3" do
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

      assert Enum.count(result) == 2
      assert Enum.at(result, 0).name == "Name Match 1"
      assert Enum.at(result, 1).name == "Name Match 2"
    end

    test "returns records that the given term matches case-insensitively" do
      prepare_test_accounts()

      attrs = %{"search_term" => "NAME MATCH"}
      result =
        Account
        |> SearchParser.to_query(attrs, [:name])
        |> Repo.all()

      assert Enum.count(result) == 2
      assert Enum.at(result, 0).name == "Name Match 1"
      assert Enum.at(result, 1).name == "Name Match 2"
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

      assert Enum.count(result) == 0
    end

    test "returns original query if search_term is missing" do
      original = Account
      attrs    = %{"wrong_attr" => "Name Match 1"}
      result   = SearchParser.to_query(original, attrs, [:name])

      assert result == original
    end
  end
end
