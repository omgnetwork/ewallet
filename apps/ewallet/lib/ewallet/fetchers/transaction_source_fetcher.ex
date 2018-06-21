defmodule EWallet.TransactionSourceFetcher do
  @moduledoc """
  Handles the logic for fetching the token and the from and to wallets.
  """
  alias EWallet.WalletFetcher
  alias EWalletDB.{Account, User}

  def fetch_from(%{"from_account_id" => _, "from_user_id" => _}) do
    {:error, :from_account_id_and_from_user_id_exclusive}
  end

  def fetch_from(%{"from_account_id" => _, "from_provider_user_id" => _}) do
    {:error, :from_account_id_and_from_provider_user_id_exclusive}
  end

  def fetch_from(%{"from_user_id" => _, "from_provider_user_id" => _}) do
    {:error, :from_user_id_and_from_provider_user_id_exclusive}
  end

  def fetch_from(%{"from_account_id" => from_account_id, "from_address" => from_address}) do
    with %Account{} = account <- Account.get(from_account_id) || {:error, :account_id_not_found},
         {:ok, wallet} <- WalletFetcher.get(account, from_address) do
     {:ok, %{
       from_account: account,
       from_wallet: wallet
     }}
    else
      error -> error
    end
  end

  def fetch_from(%{"from_user_id" => from_user_id, "from_address" => from_address}) do
    with %User{} = user <- User.get(from_user_id) || {:error, :user_id_not_found},
         {:ok, wallet} <- WalletFetcher.get(user, from_address) do
     {:ok, %{
       from_user: user,
       from_wallet: wallet
     }}
    else
      error -> error
    end
  end

  def fetch_from(%{"from_provider_user_id" => from_provider_user_id, "from_address" => from_address}) do
    with %User{} = user <- User.get_by_provider_user_id(from_provider_user_id) || {:error, :provider_user_id_not_found},
         {:ok, wallet} <- WalletFetcher.get(user, from_address) do
     {:ok, %{
       from_user: user,
       from_wallet: wallet
     }}
    else
      error -> error
    end
  end

  def fetch_from(%{"from_address" => from_address}) do
    with {:ok, wallet} <- WalletFetcher.get(nil, from_address) do
      case is_nil(wallet.account_uuid) do
        true ->
          {:ok, %{
            from_user: wallet.user,
            from_wallet: wallet
          }}
        false ->
          {:ok, %{
            from_account: wallet.account,
            from_wallet: wallet
          }}
      end
    else
      error -> error
    end
  end

  def fetch_from(%{"from_account_id" => from_account_id}) do
    fetch_from(%{"from_account_id" => from_account_id, "from_address" => nil})
  end

  def fetch_from(%{"from_user_id" => from_user_id}) do
    fetch_from(%{"from_user_id" => from_user_id, "from_address" => nil})
  end

  def fetch_from(%{"from_provider_user_id" => from_provider_user_id}) do
    fetch_from(%{"from_provider_user_id" => from_provider_user_id, "from_address" => nil})
  end

  def fetch_from(_) do
    {:error, :invalid_parameter}
  end

  def fetch_to(%{"to_account_id" => _, "to_user_id" => _}) do
    {:error, :to_account_id_and_to_user_id_exclusive}
  end

  def fetch_to(%{"to_account_id" => _, "to_provider_user_id" => _}) do
    {:error, :to_account_id_and_to_provider_user_id_exclusive}
  end

  def fetch_to(%{"to_user_id" => _, "to_provider_user_id" => _}) do
    {:error, :to_user_id_and_to_provider_user_id_exclusive}
  end

  def fetch_to(%{"to_account_id" => to_account_id, "to_address" => to_address}) do
    with %Account{} = account <- Account.get(to_account_id) || {:error, :account_id_not_found},
         {:ok, wallet} <- WalletFetcher.get(account, to_address) do
     {:ok, %{
       to_account: account,
       to_wallet: wallet
     }}
    else
      error -> error
    end
  end

  def fetch_to(%{"to_user_id" => to_user_id, "to_address" => to_address}) do
    with %User{} = user <- User.get(to_user_id) || {:error, :user_id_not_found},
         {:ok, wallet} <- WalletFetcher.get(user, to_address) do
     {:ok, %{
       to_user: user,
       to_wallet: wallet
     }}
    else
      error -> error
    end
  end

  def fetch_to(%{"to_provider_user_id" => to_provider_user_id, "to_address" => to_address}) do
    with %User{} = user <- User.get_by_provider_user_id(to_provider_user_id) || {:error, :provider_user_id_not_found},
         {:ok, wallet} <- WalletFetcher.get(user, to_address) do
     {:ok, %{
       to_user: user,
       to_wallet: wallet
     }}
    else
      error -> error
    end
  end

  def fetch_to(%{"to_address" => to_address}) do
    with {:ok, wallet} <- WalletFetcher.get(nil, to_address) do
      case is_nil(wallet.account_uuid) do
        true ->
          {:ok, %{
            to_user: wallet.user,
            to_wallet: wallet
          }}
        false ->
          {:ok, %{
            to_account: wallet.account,
            to_wallet: wallet
          }}
      end
    else
      error -> error
    end
  end

  def fetch_to(%{"to_account_id" => to_account_id}) do
    fetch_to(%{"to_account_id" => to_account_id, "to_address" => nil})
  end

  def fetch_to(%{"to_user_id" => to_user_id}) do
    fetch_to(%{"to_user_id" => to_user_id, "to_address" => nil})
  end

  def fetch_to(%{"to_provider_user_id" => to_provider_user_id}) do
    fetch_to(%{"to_provider_user_id" => to_provider_user_id, "to_address" => nil})
  end

  def fetch_to(_) do
    {:error, :invalid_parameter}
  end
end
