# Copyright 2018-2019 OmiseGO Pte Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule AdminAPI.V1.AccountMembershipDeprecatedController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler

  alias EWallet.{
    AccountMembershipPolicy,
    AdminUserPolicy,
    AccountPolicy,
    Bouncer.Permission
  }

  alias EWallet.Web.{Orchestrator, Paginator, V1.MembershipOverlay}
  alias EWalletDB.{Account, Membership, User}

  @doc """
  Lists the admins that are assigned to the given account.
  """
  def all_admin_for_account(conn, %{"id" => account_id} = attrs) do
    with %Account{} = account <-
           Account.get(account_id, preload: [memberships: [:user, :role]]) ||
             {:error, :unauthorized},
         {:ok, _} <- authorize(:get, conn.assigns, account),
         {:ok, %{query: query}} <- authorize(:all, conn.assigns, nil),
         true <- !is_nil(query) || {:error, :unauthorized},
         attrs <- transform_member_filter_attrs(attrs),
         query <- Membership.query_all_users_by_account(account, query),
         %Paginator{} = memberships <- Orchestrator.query(query, MembershipOverlay, attrs) do
      render(conn, :memberships, %{memberships: memberships})
    else
      {:error, :not_allowed, field} ->
        handle_error(conn, :query_field_not_allowed, field_name: field)

      {:error, error} ->
        handle_error(conn, error)

      {:error, code, description} ->
        handle_error(conn, code, description)
    end
  end

  def all_admin_for_account(conn, _), do: handle_error(conn, :missing_id)

  # Transform the filter attributes to the ones expected by
  # the Orchestrator + MembershipOverlay.
  defp transform_member_filter_attrs(attrs) do
    user_filterables =
      MembershipOverlay.filter_fields()
      |> Keyword.get(:user)
      |> Enum.map(fn {field, _type} -> Atom.to_string(field) end)

    attrs
    |> transform_user_filter_attrs("match_any", user_filterables)
    |> transform_user_filter_attrs("match_all", user_filterables)
  end

  defp transform_user_filter_attrs(attrs, match_type, filterables) do
    case attrs[match_type] do
      nil ->
        attrs

      _ ->
        match_attrs = transform_user_filter_attrs(attrs[match_type], filterables)
        Map.put(attrs, match_type, match_attrs)
    end
  end

  defp transform_user_filter_attrs(filters, filterables) do
    Enum.map(filters, fn filter ->
      case Enum.member?(filterables, filter["field"]) do
        true -> Map.put(filter, "field", "user." <> filter["field"])
        false -> filter
      end
    end)
  end

  @spec authorize(:all | :create | :get | :update | :delete, map(), map()) ::
          {:ok, %Permission{}} | {:error, %Permission{}} | no_return()
  defp authorize(action, actor, %Account{} = account) do
    AccountPolicy.authorize(action, actor, account)
  end

  defp authorize(action, actor, %User{} = user) do
    AdminUserPolicy.authorize(action, actor, user)
  end

  defp authorize(action, actor, membership) do
    AccountMembershipPolicy.authorize(action, actor, membership)
  end
end
