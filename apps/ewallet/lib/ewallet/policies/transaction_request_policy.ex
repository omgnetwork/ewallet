defmodule EWallet.TransactionRequestPolicy do
  @moduledoc """
  The authorization policy for accounts.
  """
  @behaviour Bodyguard.Policy
  alias EWallet.PolicyHelper
  alias EWalletDB.{Account, TransactionRequest, Wallet}

  def authorize(:all, _admin_user_or_key, nil), do: true

  def authorize(:get, _admin_user_or_key, %TransactionRequest{account_uuid: nil}) do
    true
  end

  def authorize(:get, %{key: key}, %TransactionRequest{account_uuid: account_uuid}) do
    Account.descendant?(key.account, account_uuid)
  end

  def authorize(:get, %{admin_user: user}, %TransactionRequest{account_uuid: account_uuid}) do
    PolicyHelper.viewer_authorize(user, account_uuid)
  end

  # Anyone can create a request for a user
  def authorize(:create, _admin_user_or_key, %{"user_id" => user_id}) when not is_nil(user_id) do
    true
  end

  # Check with the passed attributes if the current accessor can
  # create a request for the account
  def authorize(:create, params, %{"address" => address}) do
    with %Wallet{} = wallet <- Wallet.get(address) do
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

  def authorize(:create, %{key: key}, %{"account_id" => account_id}) do
    Account.descendant?(key.account, account_id)
  end

  def authorize(:create, %{admin_user: admin_user}, %{"account_uuid" => account_uuid}) do
    PolicyHelper.admin_authorize(admin_user, account_uuid)
  end

  def authorize(:create, %{admin_user: admin_user}, %{"account_id" => account_id}) do
    PolicyHelper.admin_authorize(admin_user, account_id)
  end

  def authorize(_, _, _), do: false
end
