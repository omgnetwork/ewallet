defmodule EWallet.AccountFetcher do
  @moduledoc """
  Handles retrieval of accounts from params for transactions.
  """
  alias EWallet.WalletFetcher
  alias EWalletDB.{Repo, Account}

  def fetch_exchange_account(%{
    "token_id" => _token_id,
  }, from) do
    {:ok, from}
  end

  def fetch_exchange_account(%{
        "from_token_id" => same_token_id,
        "to_token_id" => same_token_id
      }, from) do
    {:ok, from}
  end

  def fetch_exchange_account(%{
        "from_token_id" => _from_token_id,
        "to_token_id" => _to_token_id,
        "exchange_account_id" => exchange_account_id
      } = attrs, from) do
    with %Account{} = account <- Account.get(exchange_account_id) || :account_id_not_found,
         {:ok, wallet} <- WalletFetcher.get(account, attrs["exchange_wallet_address"]) do
     return_from(from, account, wallet)
    else
      error ->
        error
    end
  end

  def fetch_exchange_account(%{
        "from_token_id" => from_token_id,
        "to_token_id" => to_token_id,
        "exchange_wallet_address" => exchange_wallet_address
      }, from) do
    case from_token_id == to_token_id do
      true ->
        {:ok, nil}

      false ->
        with {:ok, wallet} <- WalletFetcher.get(nil, exchange_wallet_address),
             wallet <- Repo.preload(wallet, [:account]),
             %Account{} = account <- wallet.account || :exchange_address_not_account do
          return_from(from, account, wallet)
        else
          {:error, :wallet_not_found} ->
            {:error, :exchange_account_wallet_not_found}
          error ->
            error
        end
    end
  end

  def fetch_exchange_account(_attrs, _from) do
    {:error, :invalid_parameter, "'exchange_account_id' or 'exchange_wallet_address' is required.'"}
  end

  defp return_from(from, account, wallet) do
    from =
      from
      |> Map.put(:exchange_account_uuid, account.uuid)
      |> Map.put(:exchange_wallet_address, wallet.address)

    {:ok, from}
  end
end
