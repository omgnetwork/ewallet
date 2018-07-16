defmodule EWallet.ExchangeAccountFetcher do
  @moduledoc """
  Fetch exchange account and/or exchange wallet.
  """
  alias EWallet.WalletFetcher
  alias EWalletDB.Account

  def fetch(%{
        "exchange_account_id" => exchange_account_id,
        "exchange_wallet_address" => exchange_wallet_address
      })
      when not is_nil(exchange_account_id) and not is_nil(exchange_wallet_address) do
    with %Account{} = exchange_account <-
           Account.get(exchange_account_id) || {:error, :exchange_account_id_not_found},
         {:ok, exchange_wallet} <- WalletFetcher.get(exchange_account, exchange_wallet_address) do
      {:ok, exchange_wallet}
    else
      {:error, :account_wallet_not_found} ->
        {:error, :exchange_account_wallet_not_found}

      {:error, :account_wallet_mismatch} ->
        {:error, :exchange_account_wallet_mismatch}

      error ->
        error
    end
  end

  def fetch(%{"exchange_account_id" => exchange_account_id})
      when not is_nil(exchange_account_id) do
    with %Account{} = exchange_account <-
           Account.get(exchange_account_id) || {:error, :exchange_account_id_not_found},
         exchange_wallet <- Account.get_primary_wallet(exchange_account) do
      {:ok, exchange_wallet}
    else
      error ->
        error
    end
  end

  def fetch(%{
        "exchange_wallet_address" => exchange_wallet_address
      })
      when not is_nil(exchange_wallet_address) do
    with %Account{} = exchange_account <-
           Account.get(exchange_account_id) || {:error, :exchange_account_id_not_found},
         {:ok, exchange_wallet} <- WalletFetcher.get(exchange_account, exchange_wallet_address) do
      {:ok, exchange_wallet}
    else
      {:error, :account_wallet_not_found} ->
        {:error, :exchange_account_wallet_not_found}

      {:error, :account_wallet_mismatch} ->
        {:error, :exchange_account_wallet_mismatch}

      error ->
        error
    end
  end

  def fetch(_), do: {:ok, nil}
end
