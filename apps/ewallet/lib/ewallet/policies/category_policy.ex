defmodule EWallet.CategoryPolicy do
  @moduledoc """
  The authorization policy for categories.
  """
  alias EWalletDB.User
  @behaviour Bodyguard.Policy

  # Any user can list categories
  def authorize(:all, _user_id, nil), do: true

  # Any user can get a category
  def authorize(:get, _user_id, _category_id), do: true

  # Only users with an admin role on master account can create a category
  def authorize(:create, user_id, nil), do: User.master_admin?(user_id)

  # Only users with an admin role on master account can edit a category
  def authorize(:update, user_id, _category_id), do: User.master_admin?(user_id)

  # Only users with an admin role on master account can delete a category
  def authorize(:delete, user_id, _category_id), do: User.master_admin?(user_id)

  # Catch-all: deny everything else
  def authorize(_, _, _), do: false
end
