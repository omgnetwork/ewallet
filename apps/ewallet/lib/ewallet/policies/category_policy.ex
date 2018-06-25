defmodule EWallet.CategoryPolicy do
  @moduledoc """
  The authorization policy for categories.
  """
  alias EWalletDB.{User, Key}
  @behaviour Bodyguard.Policy

  # Any user can list categories
  def authorize(:all, _user_or_key, nil), do: true

  # Any user can get a category
  def authorize(:get, _user_or_key, _category_id), do: true

  # Only users with an admin role on master account can create a category
  def authorize(:create, %User{} = user, nil) do
    User.master_admin?(user.id)
  end

  def authorize(:create, %Key{} = _key, nil) do
    true
  end

  # Only users with an admin role on master account can edit a category
  def authorize(:update, %User{} = user, _category_id) do
    User.master_admin?(user.id)
  end

  def authorize(:update, %Key{} = _key, _category_id) do
    true
  end

  # Only users with an admin role on master account can delete a category
  def authorize(:delete, %User{} = user, _category_id) do
    User.master_admin?(user.id)
  end

  def authorize(:delete, %Key{} = _key, _category_id) do
    true
  end

  # Catch-all: deny everything else
  def authorize(_, _, _), do: false
end
