defmodule EWallet.TransactionFormatter do
  @moduledoc """
  Format a transaction the way LocalLedger expects it.
  """
  alias EWalletDB.Account
  alias EWalletDB.Helpers.Preloader

  def format(%{from_token: %{uuid: from}, to_token: %{uuid: to}} = transaction) when from == to do
    same_token_transaction(transaction)
  end

  def format(%{from_token: %{uuid: from}, to_token: %{uuid: to}} = transaction) when from != to do
    cross_token_transaction(transaction)
  end

  defp same_token_transaction(transaction) do
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

  def cross_token_transaction(transaction) do
    exchange_wallet =
      transaction
      |> Preloader.preload(:exchange_account)
      |> Map.get(:exchange_account)
      |> Account.get_primary_wallet()

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
        },
        %{
          "address" => exchange_wallet.address,
          "amount" => transaction.to_amount,
          "token" => %{
            "id" => transaction.to_token.id,
            "metadata" => transaction.to_token.metadata
          },
          "metadata" => exchange_wallet.metadata
        }
      ],
      "credits" => [
        %{
          "address" => exchange_wallet.address,
          "amount" => transaction.from_amount,
          "token" => %{
            "id" => transaction.from_token.id,
            "metadata" => transaction.from_token.metadata
          },
          "metadata" => exchange_wallet.metadata
        },
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
