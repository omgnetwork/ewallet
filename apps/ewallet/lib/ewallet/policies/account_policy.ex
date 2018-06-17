defmodule EWallet.AccountPolicy do
  @moduledoc """
  The authorization policy for accounts.
  """
  @behaviour Bodyguard.Policy
  alias EWalletDB.User

  # Allowed by any role including none
  def authorize(:all, _user_id, nil), do: true

  # Fetches the user role then authorize by role
  def authorize(action, user_id, account_id) do
    user_id
    |> User.get_role(account_id)
    |> do_authorize(action)
  end

  # Allowed "admin" actions
  defp do_authorize("admin", _action), do: true

  # Allowed "viewer" actions
  defp do_authorize("viewer", :all), do: true
  defp do_authorize("viewer", :get), do: true

  # Forbidden "viewer" actions
  defp do_authorize("viewer", :create), do: false
  defp do_authorize("viewer", :update), do: false
  defp do_authorize("viewer", :delete), do: false

  # Catch-all: deny everything else
  defp do_authorize(_role, _action), do: false
end
