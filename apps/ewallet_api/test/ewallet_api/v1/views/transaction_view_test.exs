defmodule EWalletAPI.V1.TransactionViewTest do
  use EWalletAPI.ViewCase, :v1
  alias EWalletAPI.V1.TransactionView
  alias EWallet.Web.{Date, V1.TokenSerializer}

  describe "EWalletAPI.V1.TransactionView.render/2" do
    test "renders transaction.json with correct structure" do
      transaction = insert(:transaction)

      expected = %{
        version: @expected_version,
        success: true,
        data: %{
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
            token_id: transaction.from_token.id,
            token: TokenSerializer.serialize(transaction.from_token)
          },
          to: %{
            object: "transaction_source",
            address: transaction.to,
            amount: transaction.to_amount,
            account: nil,
            account_id: nil,
            user: nil,
            user_id: nil,
            token_id: transaction.to_token.id,
            token: TokenSerializer.serialize(transaction.to_token)
          },
          exchange: %{
            object: "exchange",
            rate: 1,
            calculated_at: nil,
            exchange_pair: nil,
            exchange_pair_id: nil,
            exchange_account: nil,
            exchange_account_id: nil,
            exchange_wallet: nil,
            exchange_wallet_address: nil
          },
          metadata: %{some: "metadata"},
          encrypted_metadata: %{},
          status: transaction.status,
          error_code: nil,
          error_description: nil,
          created_at: Date.to_iso8601(transaction.inserted_at),
          updated_at: Date.to_iso8601(transaction.updated_at)
        }
      }

      assert render(TransactionView, "transaction.json", transaction: transaction) == expected
    end
  end
end
