defmodule EWallet.TransactionFormatter do
  @moduledoc """
  Format a transaction the way LocalLedger expects it.
  """
  def format(transaction) do
    %{
      "idempotency_token" => transaction.idempotency_token,
      "metadata" => transaction.metadata,
      "debits" => [
        %{
          "address" => transaction.from_wallet.address,
          "amount" => transaction.from_amount,
          "token" => %{
            "id" => transaction.from_token.id,
            "metadata" => transaction.from_token.metadata
          },
          "metadata" => transaction.from_wallet.metadata
        }
      ],
      "credits" => [
        %{
          "address" => transaction.to_wallet.address,
          "amount" => transaction.to_amount,
          "token" => %{
            "id" => transaction.to_token.id,
            "metadata" => transaction.to_token.metadata
          },
          "metadata" => transaction.to_wallet.metadata
        }
      ]
    }
  end
end
