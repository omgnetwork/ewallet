defmodule EWallet.WalletFetcher do
  @moduledoc """
  Handles the retrieval of wallets from the eWallet database.
  """
  alias EWalletDB.{User, Wallet, Account}

  @spec get(%User{} | %Account{} | nil, String.t() | nil) :: {:ok, %Wallet{}} | {:error, atom()}
  def get(%User{} = user, nil) do
    {:ok, User.get_primary_wallet(user)}
  end

  def get(%Account{} = account, nil) do
    {:ok, Account.get_primary_wallet(account)}
  end

  def get(nil, address) do
    with %Wallet{} = wallet <- Wallet.get(address) || :wallet_not_found do
      {:ok, wallet}
    else
      error -> {:error, error}
    end
  end

  def get(%User{} = user, address) do
    with %Wallet{} = wallet <- Wallet.get(address) || :user_wallet_not_found,
         true <- wallet.user_uuid == user.uuid || :user_wallet_mismatch do
      {:ok, wallet}
    else
      error -> {:error, error}
    end
  end

  def get(%Account{} = account, address) do
    with %Wallet{} = wallet <- Wallet.get(address) || :account_wallet_not_found,
         true <- wallet.account_uuid == account.uuid || :account_wallet_mismatch do
      {:ok, wallet}
    else
      error -> {:error, error}
    end
  end

  def get(_, _), do: {:error, :invalid_parameter}
end
