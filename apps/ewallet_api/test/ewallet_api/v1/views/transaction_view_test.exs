defmodule EWalletAPI.V1.TransactionViewTest do
  use EWalletAPI.ViewCase, :v1
  alias EWalletAPI.V1.{JSON.MintedTokenSerializer, TransactionView}
  alias EWallet.Web.Date
  alias EWalletDB.Repo

  describe "EWalletAPI.V1.TransactionView.render/2" do
    test "renders transaction.json with correct structure" do
      transaction = :transfer |> insert() |> Repo.preload(:minted_token)

      expected = %{
        version: @expected_version,
        success: true,
        data: %{
          object: "transaction",
          id: transaction.id,
          idempotency_token: transaction.idempotency_token,
          amount: transaction.amount,
          minted_token: MintedTokenSerializer.serialize(transaction.minted_token),
          from: transaction.from,
          to: transaction.to,
          status: transaction.status,
          created_at: Date.to_iso8601(transaction.inserted_at),
          updated_at: Date.to_iso8601(transaction.updated_at)
        }
      }

      assert render(TransactionView, "transaction.json",
                    transaction: transaction) == expected
    end
  end
end
