defmodule EWallet.Web.MatchAnyParserTest do
  use EWallet.DBCase
  import EWalletDB.Factory
  alias EWallet.Web.MatchAnyParser
  alias EWalletDB.{Repo, Transaction}

  describe "to_query/3" do
    test "filter" do
      txn_1 = insert(:transaction, status: "pending")
      txn_2 = insert(:transaction, status: "confirmed")
      txn_3 = insert(:transaction, status: "approved")
      txn_4 = insert(:transaction, status: "rejected")

      attrs = %{
        "match_any" => [
          %{
            "field" => "status",
            "comparator" => "eq",
            "value" => "confirmed"
          },
          %{
            "field" => "status",
            "comparator" => "eq",
            "value" => "approved"
          }
        ]
      }

      query = MatchAnyParser.to_query(Transaction, attrs, [:status])
      result = Repo.all(query)

      refute Enum.any?(result, fn txn -> txn.id == txn_1.id end)
      assert Enum.any?(result, fn txn -> txn.id == txn_2.id end)
      assert Enum.any?(result, fn txn -> txn.id == txn_3.id end)
      refute Enum.any?(result, fn txn -> txn.id == txn_4.id end)
    end
  end
end
