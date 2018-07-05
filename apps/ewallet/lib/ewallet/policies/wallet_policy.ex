defmodule EWallet.WalletPolicy do
  @moduledoc """
  The authorization policy for accounts.
  """
  @behaviour Bodyguard.Policy
  alias EWallet.{PolicyHelper, AccountPolicy, UserPolicy}
  alias EWalletDB.{Account, User, Wallet}

  def authorize(:all, params, %Account{} = account) do
    AccountPolicy.authorize(:get, params, account.id)
  end

  def authorize(:all, params, %User{} = user) do
    UserPolicy.authorize(:get, params, user)
  end

  def authorize(:all, _params, nil), do: true

  # Anyone can manage a user's wallet
  def authorize(_action, _admin_user_or_key, %Wallet{account_uuid: nil}) do
    true
  end

  # Anyone can create a wallet for a user
  def authorize(:create, _admin_user_or_key, %{"user_id" => user_id}) when not is_nil(user_id) do
    true
  end

  # Check with the passed attributes if the current accessor can
  # create a wallet for the account
  def authorize(:create, %{key: key}, %{"account_id" => account_id}) do
    Account.descendant?(key.account, account_id)
  end

  def authorize(:create, %{admin_user: admin_user}, %{"account_id" => account_id}) do
    PolicyHelper.admin_authorize(admin_user, account_id)
  end

  # Need admin rights to do anything else
  def authorize(_action, %{key: key}, %Wallet{account_uuid: uuid} = _wallet) do
    with %Account{} = account <- Account.get_by(uuid: uuid) || {:error, :unauthorized} do
      Account.descendant?(key.account, account.id)
    else
      error -> error
    end
  end

  def authorize(_action, %{admin_user: admin_user}, %Wallet{account_uuid: uuid} = _wallet) do
    with %Account{} = account <- Account.get_by(uuid: uuid) || {:error, :unauthorized} do
      PolicyHelper.admin_authorize(admin_user, account.id)
    else
      error -> error
    end
  end

  def authorize(_, _, _), do: false
end
