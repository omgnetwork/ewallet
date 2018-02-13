defmodule EWallet.AccountPolicy do
  @moduledoc """
  The authorization policy for accounts.
  """
  @behaviour Bodyguard.Policy
  alias EWalletDB.User

  # Fetches the user role then authorize by role
  def authorize(action, user_id, account_id)
    when is_binary(user_id) and byte_size(user_id) > 0
    and is_binary(account_id) and byte_size(account_id) > 0
  do
    user_id
    |> User.get_role(account_id)
    |> do_authorize(action)
  end
  def authorize(_, _, _), do: {:error, :invalid_parameter}

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
