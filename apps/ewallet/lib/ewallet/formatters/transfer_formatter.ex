defmodule EWallet.TransferFormatter do
  @moduledoc """
  Format a transfer the way LocalLedger expects it.
  """
  def format(transfer) do
    %{
      "idempotency_token" => transfer.idempotency_token,
      "metadata" => transfer.metadata,
      "token" => %{
        "id" => transfer.token.id,
        "metadata" => transfer.token.metadata
      },
      "debits" => [
        %{
          "address" => transfer.from_wallet.address,
          "amount" => transfer.amount,
          "metadata" => transfer.from_wallet.metadata
        }
      ],
      "credits" => [
        %{
          "address" => transfer.to_wallet.address,
          "amount" => transfer.amount,
          "metadata" => transfer.to_wallet.metadata
        }
      ]
    }
  end
end
