defmodule EWallet.Web.V1.TransactionSerializerTest do
  use EWallet.Web.SerializerCase, :v1
  alias Ecto.Association.NotLoaded
  alias EWallet.Web.V1.{TransactionSerializer, MintedTokenSerializer}
  alias EWallet.Web.Date
  alias EWalletDB.{Repo, MintedToken}

  describe "serialize/1 for single transaction" do
    test "serializes into correct V1 transaction format" do
      transaction = insert(:transfer)
      minted_token = MintedToken.get_by(uuid: transaction.minted_token_uuid)

      expected = %{
        object: "transaction",
        id: transaction.id,
        idempotency_token: transaction.idempotency_token,
        from: %{
          object: "transaction_source",
          address: transaction.from,
          amount: transaction.amount,
          minted_token_id: minted_token.id,
          minted_token: MintedTokenSerializer.serialize(minted_token)
        },
        to: %{
          object: "transaction_source",
          address: transaction.to,
          amount: transaction.amount,
          minted_token_id: minted_token.id,
          minted_token: MintedTokenSerializer.serialize(minted_token)
        },
        exchange: %{
          object: "exchange",
          rate: 1
        },
        metadata: %{some: "metadata"},
        encrypted_metadata: %{},
        status: transaction.status,
        created_at: Date.to_iso8601(transaction.inserted_at),
        updated_at: Date.to_iso8601(transaction.updated_at)
      }

      assert TransactionSerializer.serialize(transaction) == expected
    end

    test "serializes to nil if the transaction is not loaded" do
      assert TransactionSerializer.serialize(%NotLoaded{}) == nil
    end
  end
end
