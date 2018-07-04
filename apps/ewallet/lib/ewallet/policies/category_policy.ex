defmodule EWallet.CategoryPolicy do
  @moduledoc """
  The authorization policy for categories.
  """
  @behaviour Bodyguard.Policy
  alias EWalletDB.{Account, User}

  # Any user can get a category
  def authorize(:get, _user_or_key, _category_id), do: true

  # Only keys belonging to master account can create a category
  # create / update / delete
  def authorize(_, %{key: key}, _category_id) do
    Account.get_master_account().uuid == key.account.uuid
  end

  # Only users with an admin role on master account can create a category
  # create / update / delete
  def authorize(_, %{admin_user: user}, _category_id) do
    User.master_admin?(user.id)
  end

  def authorize(_, _, _), do: false
end
