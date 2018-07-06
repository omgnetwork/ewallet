defmodule EWallet.TransactionPolicy do
  @moduledoc """
  The authorization policy for accounts.
  """
  @behaviour Bodyguard.Policy
  alias EWallet.{PolicyHelper, AccountPolicy}
  alias EWalletDB.{Account, Wallet}

  def authorize(:all, params, %Account{} = account) do
    AccountPolicy.authorize(:get, params, account.id)
  end

  # Everyone can see all the transactions
  def authorize(:all, _admin_user_or_key, _data), do: true

  # Anyone can get a transaction
  def authorize(:get, _admin_user_or_key, _data) do
    true
  end

  # Anyone can create a request for a user
  def authorize(:create, _admin_user_or_key, %{"from_provider_user_id" => from_provider_user_id})
      when not is_nil(from_provider_user_id) do
    true
  end

  def authorize(:create, _admin_user_or_key, %{"from_user_id" => from_user_id})
      when not is_nil(from_user_id) do
    true
  end

  # Check with the passed attributes if the current accessor can
  # create a transaction for the account
  def authorize(:create, params, %{"from_address" => from_address}) do
    with %Wallet{} = wallet <- Wallet.get(from_address) do
      case wallet.account_uuid do
        nil ->
          true

        account_uuid ->
          authorize(:create, params, %{"account_uuid" => account_uuid})
      end
    else
      _error -> {:error, :unauthorized}
    end
  end

  def authorize(:create, %{key: key}, %{"account_uuid" => account_uuid}) do
    Account.descendant?(key.account, account_uuid)
  end

  def authorize(:create, %{key: key}, %{"from_account_id" => account_id}) do
    Account.descendant?(key.account, account_id)
  end

  def authorize(:create, %{admin_user: admin_user}, %{"account_uuid" => account_uuid}) do
    PolicyHelper.admin_authorize(admin_user, account_uuid)
  end

  def authorize(:create, %{admin_user: admin_user}, %{"from_account_id" => account_id}) do
    PolicyHelper.admin_authorize(admin_user, account_id)
  end

  def authorize(_, _, _), do: false
end
