defmodule EWallet.RolePolicy do
  @moduledoc """
  The authorization policy for roles.
  """
  @behaviour Bodyguard.Policy
  alias EWalletDB.{Account, User}

  # Any user can get a role
  def authorize(:all, _user_or_key, _role_id), do: true
  def authorize(:get, _user_or_key, _role_id), do: true

  # Only keys belonging to master account can create/update a role
  def authorize(_, %{key: key}, _role_id) do
    Account.get_master_account().uuid == key.account.uuid
  end

  # Only users with an admin role on master account can create/update a role
  def authorize(_, %{admin_user: user}, _role_id) do
    User.master_admin?(user.id)
  end

  def authorize(_, _, _), do: false
end
