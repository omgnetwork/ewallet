defmodule EWallet.Web.SortParserTest do
  use EWallet.DBCase
  import EWalletDB.Factory
  alias EWallet.Web.SortParser
  alias EWalletDB.{Repo, Account}

  defp prepare_test_accounts do
    insert(:account, %{name: "account111", description: "Account DDD"})
    insert(:account, %{name: "account119", description: "Account AAA"})
    insert(:account, %{name: "account999", description: "Account ZZZ"})
  end

  describe "EWallet.Web.SortParser.to_query/4" do
    test "can sort a field by ascending order" do
      prepare_test_accounts()

      attrs = %{"sort_by" => "name", "sort_dir" => "asc"}
      sorted =
        Account
        |> SortParser.to_query(attrs, [:name])
        |> Repo.all()

      assert Enum.at(sorted, 0).name == "account111"
      assert Enum.at(sorted, 1).name == "account119"
      assert Enum.at(sorted, 2).name == "account999"
    end

    test "can sort a field by descending order" do
      prepare_test_accounts()

      attrs = %{"sort_by" => "description", "sort_dir" => "desc"}
      sorted =
        Account
        |> SortParser.to_query(attrs, [:description])
        |> Repo.all()

      assert Enum.at(sorted, 0).description == "Account ZZZ"
      assert Enum.at(sorted, 1).description == "Account DDD"
      assert Enum.at(sorted, 2).description == "Account AAA"
    end

    test "maps the given `sort_by` with `mapped_fields` before sorting" do
      prepare_test_accounts()

      mapped_fields = %{"some_description_field" => "description"}
      attrs = %{"sort_by" => "some_description_field", "sort_dir" => "desc"}
      sorted =
        Account
        |> SortParser.to_query(attrs, [:description], mapped_fields)
        |> Repo.all()

      assert Enum.at(sorted, 0).description == "Account ZZZ"
      assert Enum.at(sorted, 1).description == "Account DDD"
      assert Enum.at(sorted, 2).description == "Account AAA"
    end

    test "returns original query if sort_by is missing" do
      original = Account
      attrs    = %{"sort_dir" => "asc"}
      result   = SortParser.to_query(original, attrs, [:name])

      assert result == original
    end

    test "returns original query if sort_by is not an allowed field" do
      original = Account
      attrs    = %{"sort_by" => "name", "sort_dir" => "asc"}
      result   = SortParser.to_query(original, attrs, [:not_name])

      assert result == original
    end

    test "returns original query if sort_dir is missing" do
      original = Account
      attrs    = %{"sort_by" => "name"}
      result   = SortParser.to_query(original, attrs, [:name])

      assert result == original
    end

    test "returns original query if sort_dir is invalid" do
      original = Account
      attrs    = %{"sort_by" => "name", "sort_dir" => "not a direction"}
      result   = SortParser.to_query(original, attrs, [:name])

      assert result == original
    end
  end
end
