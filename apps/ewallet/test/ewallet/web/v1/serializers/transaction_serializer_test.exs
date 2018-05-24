defmodule EWallet.Web.V1.TransactionSerializerTest do
  use EWallet.Web.SerializerCase, :v1
  alias Ecto.Association.NotLoaded
  alias EWallet.Web.V1.{TransactionSerializer, TokenSerializer}
  alias EWallet.Web.Date
  alias EWalletDB.{Repo, Token}

  describe "serialize/1 for single transaction" do
    test "serializes into correct V1 transaction format" do
      transaction = insert(:transfer)
      token = Token.get_by(uuid: transaction.token_uuid)

      expected = %{
        object: "transaction",
        id: transaction.id,
        idempotency_token: transaction.idempotency_token,
        from: %{
          object: "transaction_source",
          address: transaction.from,
          amount: transaction.amount,
          token_id: token.id,
          token: TokenSerializer.serialize(token)
        },
        to: %{
          object: "transaction_source",
          address: transaction.to,
          amount: transaction.amount,
          token_id: token.id,
          token: TokenSerializer.serialize(token)
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
