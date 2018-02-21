defmodule EWalletAPI.V1.JSON.TransactionSerializerTest do
  use EWalletAPI.SerializerCase, :v1
  alias EWalletAPI.V1.JSON.{MintedTokenSerializer, TransactionSerializer}
  alias EWallet.Web.Date
  alias EWalletDB.Repo

  describe "serialize/1 for single transaction" do
    test "serializes into correct V1 transaction format" do
      transaction = insert(:transfer) |> Repo.preload(:minted_token)

      expected = %{
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

      assert TransactionSerializer.serialize(transaction) == expected
    end
  end
end
