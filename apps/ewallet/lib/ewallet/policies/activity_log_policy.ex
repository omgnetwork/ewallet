defmodule EWallet.ActivityLogPolicy do
  @moduledoc """
  The authorization policy for activity logs.
  """
  @behaviour Bodyguard.Policy
  alias EWalletDB.{Account, User}

  # Only keys belonging to master account can view all activity logs
  def authorize(:all, %{key: key}, _activity_log_id) do
    Account.get_master_account().uuid == key.account.uuid
  end

  # Only users with an admin role on master account can view all activity logs
  def authorize(:all, %{admin_user: user}, _activity_log_id) do
    User.master_admin?(user.id)
  end

  def authorize(_, _, _), do: false
end
