defmodule EWallet.AccountPolicy do
  @moduledoc """
  The authorization policy for accounts.
  """
  @behaviour Bodyguard.Policy
  alias EWalletDB.{Account, User, Repo, Membership}

  # all -> viewer
  # get -> viewer
  # create -> admin
  # update -> admin
  # delete -> admin

  # Allowed for any role
  def authorize(:all, _params, nil), do: true

  def authorize(:get, %{admin_user: user}, account_id) do
    with %Account{} = account <- Account.get(account_id) || {:error, :user_unauthorized},
         ancestors <- Account.get_all_ancestors(account),
         memberships <- Membership.all_by_user(user),
         membership_account_uuids <- Enum.map(memberships, fn membership -> membership.account_uuid end),
         descendants <- Account.get_all_descendants(membership_account_uuids) do
      IO.inspect(descendants)

      true
    end
  end

  # Fetches the user role then authorize by role
  def authorize(action, %{admin_user: user, account: user_account}, account_id) do
    descendant? = Account.descendant?(user_account, account_id)
    user = user |> Repo.preload([:memberships])

    user.id
    |> User.get_role(user_account.id)
    |> do_authorize(descendant?, action)
  end

  def authorize(action, %{key: _key, account: key_account}, account_id) do
    descendant? = Account.descendant?(key_account, account_id)
    do_authorize("admin", descendant?, action)
  end

  # Allowed "admin" actions
  defp do_authorize("admin", true, _action), do: true
  defp do_authorize("admin", false, _action), do: false

  # Allowed "viewer" actions
  defp do_authorize("viewer", true, :get), do: true
  defp do_authorize("viewer", false, :get), do: false

  # Forbidden "viewer" actions
  defp do_authorize("viewer", _, :create), do: false
  defp do_authorize("viewer", _, :update), do: false
  defp do_authorize("viewer", _, :delete), do: false

  # Catch-all: deny everything else
  defp do_authorize(_role, _descendant?, _action), do: false
end
