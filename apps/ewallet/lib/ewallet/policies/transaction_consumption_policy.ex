defmodule EWallet.TransactionConsumptionPolicy do
  @moduledoc """
  The authorization policy for accounts.
  """
  @behaviour Bodyguard.Policy
  alias EWallet.{AccountPolicy, PolicyHelper, TransactionRequestPolicy, UserPolicy, WalletPolicy}
  alias EWalletDB.{Account, TransactionConsumption, TransactionRequest, User, Wallet}

  def authorize(:all, params, %Account{} = account) do
    AccountPolicy.authorize(:get, params, account.id)
  end

  def authorize(:all, params, %User{} = user) do
    UserPolicy.authorize(:get, params, user)
  end

  def authorize(:all, params, %TransactionRequest{} = transaction_request) do
    TransactionRequestPolicy.authorize(:get, params, transaction_request)
  end

  def authorize(:all, params, %Wallet{} = wallet) do
    WalletPolicy.authorize(:get, params, wallet)
  end

  def authorize(:all, _admin_user_or_key, nil), do: true

  # If the account_uuid is nil, the transaction belongs to a user and can be
  # seen by any admin.
  def authorize(:get, _key_or_user, %TransactionConsumption{account_uuid: nil}) do
    true
  end

  def authorize(:get, %{key: key}, consumption) do
    Account.descendant?(key.account, consumption.account.id)
  end

  def authorize(:get, %{admin_user: user}, consumption) do
    PolicyHelper.viewer_authorize(user, consumption.account.id)
  end

  def authorize(:join, %{user: user}, consumption) do
    user
    |> User.addresses()
    |> Enum.member?(consumption.wallet_address)
  end

  def authorize(:join, params, consumption), do: authorize(:get, params, consumption)

  def authorize(:consume, params, %TransactionConsumption{} = consumption) do
    WalletPolicy.authorize(:admin, params, consumption.wallet)
  end

  # To confirm a request, we need to have admin rights on the
  # wallet of the request, except for user-only request/consumption
  def authorize(:confirm, %{end_user: end_user}, %TransactionRequest{} = request) do
    end_user.uuid == request.wallet.user_uuid
  end

  def authorize(:confirm, params, %TransactionRequest{} = request) do
    WalletPolicy.authorize(:admin, params, request.wallet)
  end

  def authorize(_, _, _), do: false
end
