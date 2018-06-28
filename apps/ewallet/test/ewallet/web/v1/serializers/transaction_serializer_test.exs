defmodule EWallet.Web.V1.TransactionSerializerTest do
  use EWallet.Web.SerializerCase, :v1
  alias Ecto.Association.NotLoaded
  alias EWallet.Web.V1.{TransactionSerializer, TokenSerializer}
  alias EWallet.Web.Date
  alias EWalletDB.{Repo, Token}

  describe "serialize/1 for single transaction" do
    test "serializes into correct V1 transaction format" do
      transaction = insert(:transaction)
      from_token = Token.get_by(uuid: transaction.from_token_uuid)
      to_token = Token.get_by(uuid: transaction.to_token_uuid)

      expected = %{
        object: "transaction",
        id: transaction.id,
        idempotency_token: transaction.idempotency_token,
        from: %{
          object: "transaction_source",
          address: transaction.from,
          amount: transaction.from_amount,
          account: nil,
          account_id: nil,
          user: nil,
          user_id: nil,
          token_id: from_token.id,
          token: TokenSerializer.serialize(from_token)
        },
        to: %{
          object: "transaction_source",
          address: transaction.to,
          amount: transaction.to_amount,
          account: nil,
          account_id: nil,
          user: nil,
          user_id: nil,
          token_id: to_token.id,
          token: TokenSerializer.serialize(to_token)
        },
        exchange: %{
          object: "exchange",
          rate: 1,
          calculated_at: nil,
          exchange_pair: nil,
          exchange_pair_id: nil
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
