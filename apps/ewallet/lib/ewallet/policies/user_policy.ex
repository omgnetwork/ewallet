defmodule EWallet.UserPolicy do
  @moduledoc """
  The authorization policy for users.
  """
  @behaviour Bodyguard.Policy
  alias EWallet.{AccountPolicy, PolicyHelper}
  alias EWalletDB.{Account, User}

  def authorize(:all, params, %Account{} = account) do
    AccountPolicy.authorize(:get, params, account.id)
  end

  def authorize(:all, _params, nil), do: true

  def authorize(:join, %{admin_user: _} = params, user) do
    authorize(:get, params, user)
  end

  def authorize(:join, %{key: _} = params, user) do
    authorize(:get, params, user)
  end

  def authorize(:join, %{end_user: end_user}, user) do
    end_user.uuid == user.uuid
  end

  # Anyone admin or key get any user
  def authorize(:get, _admin_user_or_key, _admin_user), do: true

  # Anyone can create a new user
  def authorize(:create, _admin_user_or_key, nil), do: true

  # Anyone can attempt to verify a user's email address
  def authorize(:verify_email, _admin_user_or_key, nil), do: true

  # To update a user, an account needs to be linked with that user
  def authorize(_, %{account: account}, user) do
    account_uuids = get_linked_account_uuids(user)
    Account.descendant?(account, account_uuids)
  end

  def authorize(_, %{key: key}, user) do
    account_uuids = get_linked_account_uuids(user)
    Account.descendant?(key.account, account_uuids)
  end

  def authorize(:enable_or_disable, %{admin_user: %{uuid: uuid}}, %User{uuid: uuid}) do
    false
  end

  def authorize(_, %{admin_user: admin_user}, user) do
    account_uuids = get_linked_account_uuids(user)
    PolicyHelper.admin_authorize(admin_user, account_uuids)
  end

  def authorize(_, %{end_user: end_user}, user) do
    end_user.uuid == user.uuid
  end

  def authorize(_, _, _), do: false

  defp get_linked_account_uuids(user) do
    user.uuid
    |> User.get_all_linked_accounts()
    |> Enum.map(fn account -> account.uuid end)
  end
end
