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

  # Anyone can create a wallet for a user
  def authorize(:create, %{key: _key}, %{"user_id" => user_id}) when not is_nil(user_id) do
    true
  end

  def authorize(:create, %{admin_user: _admin_user}, %{"user_id" => user_id})
      when not is_nil(user_id) do
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

  # For wallets owned by users
  def authorize(_action, params, %Wallet{user_uuid: uuid}) when not is_nil(uuid) do
    with %User{} = wallet_user <- User.get_by(uuid: uuid) || {:error, :unauthorized} do
      UserPolicy.authorize(:admin, params, wallet_user)
    else
      error -> error
    end
  end

  # For wallets owned by accounts
  def authorize(_action, params, %Wallet{account_uuid: uuid} = _wallet) when not is_nil(uuid) do
    with %Account{} = wallet_account <- Account.get_by(uuid: uuid) || {:error, :unauthorized} do
      AccountPolicy.authorize(:admin, params, wallet_account.id)
    else
      error -> error
    end
  end

  def authorize(_, _, _), do: false
end
