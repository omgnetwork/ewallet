defmodule EWallet.AdminUserPolicy do
  @moduledoc """
  The authorization policy for accounts.
  """
  @behaviour Bodyguard.Policy
  alias EWallet.PolicyHelper
  alias EWalletDB.{Account, Membership}

  # Allowed for any role, filtering is
  # handled at the controller level to only return
  # allowed records. Should this be handled here?
  def authorize(:all, _params, nil), do: true

  # access key have admin rights so we only check that the target is
  # a descendant of the access key's account.
  def authorize(_action, %{key: key}, user) do
    account_uuids = membership_account_uuids(user)
    Account.descendant?(key.account, account_uuids)
  end

  # compare current user descendant accounts
  # with passed user ancestors accounts to find match

  def authorize(:get, %{admin_user: admin_user}, user) do
    account_uuids = membership_account_uuids(user)
    PolicyHelper.viewer_authorize(admin_user, account_uuids)
  end

  # create/update/delete, or anything else.
  def authorize(_action, %{admin_user: admin_user}, user) do
    account_uuids = membership_account_uuids(user)
    PolicyHelper.admin_authorize(admin_user, account_uuids)
  end

  defp membership_account_uuids(user) do
    user
    |> Membership.all_by_user()
    |> Enum.map(fn membership -> membership.account_uuid end)
  end
end
