defmodule EWallet.RolePolicy do
  @moduledoc """
  The authorization policy for roles.
  """
  @behaviour Bodyguard.Policy
  alias EWalletDB.{Account, User}

  # Any authenticated key or admin user can retrieve the list of roles
  def authorize(:all, %{key: _}, _role_id), do: true
  def authorize(:all, %{admin_user: _}, _role_id), do: true

  # Any authenticated key or admin user can get a role
  def authorize(:get, %{key: _}, _role_id), do: true
  def authorize(:get, %{admin_user: _}, _role_id), do: true

  # Only keys belonging to master account can perform all operations
  def authorize(_, %{key: key}, _role_id) do
    Account.get_master_account().uuid == key.account.uuid
  end

  # Only users with an admin role on master account can perform all operations
  def authorize(_, %{admin_user: user}, _role_id) do
    User.master_admin?(user.id)
  end

  def authorize(_, _, _), do: false
end
