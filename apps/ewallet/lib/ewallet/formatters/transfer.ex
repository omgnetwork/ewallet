defmodule EWallet.Formatters.Transfer do
  @moduledoc """
  Format a transfer the way LocalLedger expects it.
  """
  def format(transfer) do
    %{
      "correlation_id" => transfer.idempotency_token,
      "metadata" => transfer.metadata,
      "minted_token" => %{
        "friendly_id" => transfer.minted_token.friendly_id,
        "metadata" => transfer.minted_token.metadata
      },
      "debits" => [%{
        "address" => transfer.from_balance.address,
        "amount" => transfer.amount,
        "metadata" => transfer.from_balance.metadata
      }],
      "credits" => [%{
        "address" => transfer.to_balance.address,
        "amount" => transfer.amount,
        "metadata" => transfer.to_balance.metadata
      }]
    }
  end
end
