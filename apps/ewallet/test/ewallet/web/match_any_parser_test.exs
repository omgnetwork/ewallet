defmodule EWallet.Web.MatchAnyParserTest do
  use EWallet.DBCase
  import EWalletDB.Factory
  alias EWallet.Web.MatchAnyParser
  alias EWalletDB.{Transaction}

  describe "to_query/3" do
    # test "filter" do
    #   txn_1 = insert(:transaction, status: "pending")
    #   txn_2 = insert(:transaction, status: "confirmed")
    #   txn_3 = insert(:transaction, status: "approved")
    #   txn_4 = insert(:transaction, status: "rejected")

    #   attrs = %{
    #     "match_any" => [
    #       %{
    #         "field" => "status",
    #         "comparator" => "eq",
    #         "value" => "confirmed"
    #       },
    #       %{
    #         "field" => "status",
    #         "comparator" => "eq",
    #         "value" => "approved"
    #       }
    #     ]
    #   }

    #   query = MatchAnyParser.to_query(Transaction, attrs, [:status])
    #   result = Repo.all(query)

    #   refute Enum.any?(result, fn txn -> txn.id == txn_1.id end)
    #   assert Enum.any?(result, fn txn -> txn.id == txn_2.id end)
    #   assert Enum.any?(result, fn txn -> txn.id == txn_3.id end)
    #   refute Enum.any?(result, fn txn -> txn.id == txn_4.id end)
    # end

    test "filter nested field" do
      user = insert(:user)

      txn_1 = insert(:transaction, from_user_uuid: user.uuid)
      txn_2 = insert(:transaction)
      txn_3 = insert(:transaction, to_user_uuid: user.uuid)
      txn_4 = insert(:transaction)

      attrs = %{
        "match_any" => [
          %{
            "field" => "from_user.id",
            "comparator" => "eq",
            "value" => user.id
          },
          %{
            "field" => "to_user.id",
            "comparator" => "eq",
            "value" => user.id
          }
        ]
      }

      query = MatchAnyParser.to_query(Transaction, attrs, [from_user: [:id], to_user: [:id]])
      result = Repo.all(query)

      assert Enum.any?(result, fn txn -> txn.id == txn_1.id end)
      refute Enum.any?(result, fn txn -> txn.id == txn_2.id end)
      assert Enum.any?(result, fn txn -> txn.id == txn_3.id end)
      refute Enum.any?(result, fn txn -> txn.id == txn_4.id end)
    end
  end
end
