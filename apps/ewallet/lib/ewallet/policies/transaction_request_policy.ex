defmodule EWallet.TransactionRequestPolicy do
  @moduledoc """
  The authorization policy for accounts.
  """
  @behaviour Bodyguard.Policy
  alias EWallet.{PolicyHelper, WalletPolicy}
  alias EWalletDB.{Account, TransactionRequest, Wallet}

  def authorize(:all, _admin_user_or_key, nil), do: true

  def authorize(:get, _admin_user_or_key, %TransactionRequest{account_uuid: nil}) do
    true
  end

  def authorize(:get, %{account: account}, %TransactionRequest{account_uuid: account_uuid}) do
    Account.descendant?(account, account_uuid)
  end

  def authorize(:get, %{key: key}, transaction_request) do
    authorize(:get, %{account: key.account}, transaction_request)
  end

  def authorize(:get, %{admin_user: user}, %TransactionRequest{account_uuid: account_uuid}) do
    PolicyHelper.viewer_authorize(user, account_uuid)
  end

  def authorize(:get, %{end_user: user}, %TransactionRequest{user_uuid: user_uuid}) do
    user.uuid == user_uuid
  end

  # Check with the passed attributes if the current accessor can
  # create a request for the account
  def authorize(:create, params, %Wallet{} = wallet) do
    WalletPolicy.authorize(:admin, params, wallet)
  end

  def authorize(_, _, _), do: false
end
