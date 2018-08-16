defmodule EWallet.AccountFetcher do
  @moduledoc """
  Handles retrieval of accounts from params for transactions.
  """
  alias EWallet.WalletFetcher
  alias EWalletDB.{Repo, Account}

  def fetch_exchange_account(
        %{
          "token_id" => _token_id
        },
        exchange
      ) do
    {:ok, exchange}
  end

  def fetch_exchange_account(
        %{
          "from_token_id" => same_token_id,
          "to_token_id" => same_token_id
        },
        exchange
      ) do
    {:ok, exchange}
  end

  def fetch_exchange_account(
        %{
          "from_token_id" => _from_token_id,
          "to_token_id" => _to_token_id,
          "exchange_account_id" => exchange_account_id
        } = attrs,
        exchange
      )
      when not is_nil(exchange_account_id) do
    with %Account{} = account <-
           Account.get(exchange_account_id) || :exchange_account_id_not_found,
         {:ok, wallet} <- WalletFetcher.get(account, attrs["exchange_wallet_address"]) do
      return_from(exchange, account, wallet)
    else
      error ->
        error
    end
  end

  def fetch_exchange_account(
        %{
          "from_token_id" => from_token_id,
          "to_token_id" => to_token_id,
          "exchange_wallet_address" => exchange_wallet_address
        },
        exchange
      )
      when not is_nil(exchange_wallet_address) do
    case from_token_id == to_token_id do
      true ->
        {:ok, nil}

      false ->
        with {:ok, wallet} <- WalletFetcher.get(nil, exchange_wallet_address),
             wallet <- Repo.preload(wallet, [:account]),
             %Account{} = account <- wallet.account || :exchange_address_not_account do
          return_from(exchange, account, wallet)
        else
          {:error, :wallet_not_found} ->
            {:error, :exchange_account_wallet_not_found}

          error ->
            error
        end
    end
  end

  def fetch_exchange_account(_attrs, _from) do
    {:error, :invalid_parameter,
     "Invalid parameter provided. `exchange_account_id` or `exchange_wallet_address` is required.'"}
  end

  defp return_from(exchange, account, wallet) do
    exchange =
      exchange
      |> Map.put(:exchange_account_uuid, account.uuid)
      |> Map.put(:exchange_wallet_address, wallet.address)

    {:ok, exchange}
  end
end
