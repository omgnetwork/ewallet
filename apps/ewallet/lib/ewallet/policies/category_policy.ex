defmodule EWallet.CategoryPolicy do
  @moduledoc """
  The authorization policy for accounts.
  """
  @behaviour Bodyguard.Policy

  # Allowed by any role including none
  def authorize(:all, _user_id, nil), do: true
  def authorize(:get, _user_id, _category_id), do: true
  def authorize(:create, _user_id, nil), do: true
  def authorize(:update, _user_id, _category_id), do: true
  def authorize(:delete, _user_id, _category_id), do: true

  # Catch-all: deny everything else
  def authorize(_, _, _), do: false
end
