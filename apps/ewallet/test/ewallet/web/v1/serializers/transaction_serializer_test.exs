defmodule EWallet.Web.V1.TransactionSerializerTest do
  use EWallet.Web.SerializerCase, :v1
  alias EWallet.Web.V1.{TransactionSerializer, MintedTokenSerializer}
  alias EWallet.Web.Date
  alias EWalletDB.Repo

  describe "serialize/1 for single transaction" do
    test "serializes into correct V1 transaction format" do
      transaction = :transfer |> insert() |> Repo.preload(:minted_token)

      expected = %{
        object: "transaction",
        id: transaction.id,
        idempotency_token: transaction.idempotency_token,
        from: %{
          object: "transaction_source",
          address: transaction.from,
          amount: transaction.amount,
          minted_token: MintedTokenSerializer.serialize(transaction.minted_token)
        },
        to: %{
          object: "transaction_source",
          address: transaction.to,
          amount: transaction.amount,
          minted_token: MintedTokenSerializer.serialize(transaction.minted_token),
        },
        exchange: %{
          object: "exchange",
          rate: 1,
        },
        metadata: %{some: "metadata"},
        encrypted_metadata: %{},
        status: transaction.status,
        created_at: Date.to_iso8601(transaction.inserted_at),
        updated_at: Date.to_iso8601(transaction.updated_at)
      }

      assert TransactionSerializer.serialize(transaction) == expected
    end
  end
end
