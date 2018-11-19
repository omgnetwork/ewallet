defmodule EWallet.PolicyHelper do
  @moduledoc """
  A policy helper containing the actual authorization.
  """
  alias EWalletConfig.Intersecter
  alias EWalletDB.{Account, Membership, Role}

  def admin_authorize(user, account_id_or_uuids) do
    # admin is required to create
    role = Role.get_by(name: "admin")

    user
    |> Membership.all_by_user_and_role(role)
    |> authorize(account_id_or_uuids)
  end

  def viewer_authorize(user, account_id_or_uuids) do
    # We don't care about the role here since both admin and viewer
    # are able to get accounts. We only care about getting a membership.

    user
    |> Membership.all_by_user()
    |> authorize(account_id_or_uuids)
  end

  defp authorize(memberships, account_uuids) when is_list(account_uuids) do
    with ancestors <- Account.get_all_ancestors(account_uuids),
         ancestors_uuids <- Enum.map(ancestors, fn ancestor -> ancestor.uuid end),
         membership_accounts_uuids <-
           Enum.map(memberships, fn membership -> membership.account_uuid end) do
      case Intersecter.intersect(ancestors_uuids, membership_accounts_uuids) do
        [] -> false
        _ -> true
      end
    end
  end

  defp authorize(memberships, account_id_or_uuid) do
    with %Account{} = account <-
           Account.get(account_id_or_uuid) || Account.get_by(uuid: account_id_or_uuid) ||
             {:error, :unauthorized},
         ancestors <- Account.get_all_ancestors(account),
         ancestors_uuids <- Enum.map(ancestors, fn ancestor -> ancestor.uuid end),
         membership_accounts_uuids <-
           Enum.map(memberships, fn membership -> membership.account_uuid end) do
      case Intersecter.intersect(ancestors_uuids, membership_accounts_uuids) do
        [] -> false
        _ -> true
      end
    end
  end
end
