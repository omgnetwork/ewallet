defmodule EWalletAPI.V1.TransactionViewTest do
  use EWalletAPI.ViewCase, :v1
  alias EWalletAPI.V1.TransactionView
  alias EWallet.Web.{Date, V1.AccountSerializer, V1.TokenSerializer, V1.UserSerializer}
  alias EWalletDB.Helpers.Assoc

  describe "EWalletAPI.V1.TransactionView.render/2" do
    test "renders transaction.json with correct structure" do
      transaction =
        insert(:transaction)
        |> Repo.preload([:from_token, :to_token, :from_user, :from_account, :to_user, :to_account])

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
            account: AccountSerializer.serialize(transaction.from_account),
            account_id: Assoc.get(transaction, [:from_account, :id]),
            user: UserSerializer.serialize(transaction.from_user),
            user_id: Assoc.get(transaction, [:from_user, :id]),
            token_id: transaction.from_token.id,
            token: TokenSerializer.serialize(transaction.from_token)
          },
          to: %{
            object: "transaction_source",
            address: transaction.to,
            amount: transaction.to_amount,
            account: AccountSerializer.serialize(transaction.to_account),
            account_id: Assoc.get(transaction, [:to_account, :id]),
            user: UserSerializer.serialize(transaction.to_user),
            user_id: Assoc.get(transaction, [:to_user, :id]),
            token_id: transaction.to_token.id,
            token: TokenSerializer.serialize(transaction.to_token)
          },
          exchange: %{
            object: "exchange",
            rate: nil,
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
