defmodule EWalletAPI.V1.TransactionSerializerTest do
  use EWalletAPI.SerializerCase, :v1
  alias EWalletAPI.V1.TransactionSerializer
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
          minted_token: %{
            object: "minted_token",
            id: transaction.minted_token.friendly_id,
            symbol: transaction.minted_token.symbol,
            name: transaction.minted_token.name,
            subunit_to_unit: transaction.minted_token.subunit_to_unit,
            metadata: transaction.minted_token.metadata,
            encrypted_metadata: transaction.minted_token.encrypted_metadata
          },
        },
        to: %{
          object: "transaction_source",
          address: transaction.to,
          amount: transaction.amount,
          minted_token: %{
            object: "minted_token",
            id: transaction.minted_token.friendly_id,
            symbol: transaction.minted_token.symbol,
            name: transaction.minted_token.name,
            subunit_to_unit: transaction.minted_token.subunit_to_unit,
            metadata: transaction.minted_token.metadata,
            encrypted_metadata: transaction.minted_token.encrypted_metadata
          },
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
