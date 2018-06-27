defmodule EWallet.AccountPolicy do
  @moduledoc """
  The authorization policy for accounts.
  """
  @behaviour Bodyguard.Policy
  alias EWallet.Helper
  alias EWalletDB.{Account, Membership, Role}

  # Allowed for any role, filtering is
  # handled at the controller level to only return
  # allowed records. Should this be handled here?
  def authorize(:all, _params, nil), do: true

  # access key have admin rights so we only check that the target is
  # a descendant of the access key's account.
  def authorize(_action, %{key: key}, account_id) do
    Account.descendant?(key.account, account_id)
  end

  def authorize(:get, %{admin_user: user}, account_id) do
    # We don't care about the role here since both admin and viewer
    # are able to get accounts. We only care about getting a membership.
    user
    |> Membership.all_by_user()
    |> do_authorize(account_id)
  end

  def authorize(:create, %{admin_user: user}, account_id) do
    do_admin_authorize(user, account_id)
  end

  def authorize(:update, %{admin_user: user}, account_id) do
    do_admin_authorize(user, account_id)
  end

  def authorize(:delete, %{admin_user: user}, account_id) do
    do_admin_authorize(user, account_id)
  end

  def do_admin_authorize(user, account_id) do
    # admin is required to create
    role = Role.get_by_name("admin")

    user
    |> Membership.all_by_user_and_role(role)
    |> do_authorize(account_id)
  end

  def do_authorize(memberships, account_id) do
    # optimize this by allowing ancestors to be queried by account_id
    # move this to another module.
    with %Account{} = account <- Account.get(account_id) || {:error, :unauthorized},
         ancestors <- Account.get_all_ancestors(account),
         ancestors_uuids <- Enum.map(ancestors, fn ancestor -> ancestor.uuid end),
         membership_accounts_uuids <-
           Enum.map(memberships, fn membership -> membership.account_uuid end) do
      case Helper.intersect(ancestors_uuids, membership_accounts_uuids) do
        [] -> false
        _ -> true
      end
    end
  end
end
