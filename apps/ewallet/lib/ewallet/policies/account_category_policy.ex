defmodule EWallet.AccountCategoryPolicy do
  @moduledoc """
  The authorization policy for accounts.
  """
  @behaviour Bodyguard.Policy

  # Allowed by any role including none
  def authorize(:all, _user_id, nil), do: true

  # Catch-all: deny everything else
  def authorize(_, _, _), do: false
end
