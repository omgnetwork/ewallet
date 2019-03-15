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

defmodule AdminAPI.V1.AccountMembershipController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler

  alias EWallet.{
    AccountMembershipPolicy,
    AdminUserPolicy,
    AccountPolicy,
    Bouncer.Permission,
    UserGate
  }

  alias EWallet.Web.{Orchestrator, Originator, V1.MembershipOverlay}
  alias EWalletDB.{Account, Membership, Role, User}

  @doc """
  Lists the users that are assigned to the given account.
  """
  def all_for_account(conn, %{"id" => account_id} = attrs) do
    with %Account{} = account <-
           Account.get(account_id, preload: [memberships: [:user, :role]]) ||
             {:error, :unauthorized},
         {:ok, _} <- authorize(:get, conn.assigns, account),
         {:ok, %{query: query}} <- authorize(:all, conn.assigns, nil),
         attrs <- transform_user_filter_attrs(attrs),
         query <- Membership.all_by_account(account, query),
         memberships <- Orchestrator.query(query, MembershipOverlay, attrs) do
      render(conn, :memberships, %{memberships: memberships})
    else
      {:error, :not_allowed, field} ->
        handle_error(conn, :query_field_not_allowed, field_name: field)

      {:error, error} ->
        handle_error(conn, error)
    end
  end

  def all_for_account(conn, _), do: handle_error(conn, :invalid_parameter)

  # Transform the filter attributes to the ones expected by
  # the Orchestrator + MembershipOverlay.
  defp transform_user_filter_attrs(attrs) do
    user_filterables =
      MembershipOverlay.filter_fields()
      |> Keyword.get(:user)
      |> Enum.map(fn field -> Atom.to_string(field) end)

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

  @doc """
  Assigns the user to the given account and role.
  """
  def assign_user(conn, attrs) do
    with %Account{} = account <- Account.get(attrs["account_id"]) || {:error, :unauthorized},
         {:ok, _} <- authorize(:get, conn.assigns, account),
         {:ok, _} <- authorize(:create, conn.assigns, %User{}),
         {:ok, _} <-
           authorize(:create, conn.assigns, %Membership{
             account: account,
             account_uuid: account.uuid
           }),
         {:ok, user_or_email} <- UserGate.get_user_or_email(attrs),
         %Role{} = role <-
           Role.get_by(name: attrs["role_name"]) || {:error, :role_name_not_found},
         {:ok, redirect_url} <- UserGate.validate_redirect_url(attrs["redirect_url"]),
         originator <- Originator.extract(conn.assigns),
         {:ok, _} <-
           UserGate.assign_or_invite(user_or_email, account, role, redirect_url, originator) do
      render(conn, :empty, %{success: true})
    else
      {true, :user_id_not_found} ->
        handle_error(conn, :user_id_not_found)

      {:error, code} when is_atom(code) ->
        handle_error(conn, code)

      {:error, %Permission{} = permission} ->
        handle_error(conn, permission)

      # Matches a different error format returned by Membership.assign_user/2
      {:error, changeset} ->
        handle_error(conn, :invalid_parameter, changeset)

      {:error, code, description} ->
        handle_error(conn, code, description)
    end
  end

  @doc """
  Unassigns the user from the given account.
  """
  def unassign_user(conn, %{
        "user_id" => user_id,
        "account_id" => account_id
      })
      when not is_nil(account_id) and not is_nil(user_id) do
    with %Account{} = account <- Account.get(account_id) || {:error, :unauthorized},
         {:ok, _} <- authorize(:get, conn.assigns, account),
         %User{} = user <- User.get(user_id) || {:error, :unauthorized},
         {:ok, _} <- authorize(:get, conn.assigns, user),
         %Membership{} = membership <- Membership.get_by_member_and_account(user, account),
         {:ok, _} <- authorize(:delete, conn.assigns, membership),
         originator <- Originator.extract(conn.assigns),
         {:ok, _} <- Membership.unassign(user, account, originator) do
      render(conn, :empty, %{success: true})
    else
      nil -> handle_error(conn, :unauthorized)
      {:error, error} -> handle_error(conn, error)
    end
  end

  def unassign_user(conn, _attrs), do: handle_error(conn, :invalid_parameter)

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
