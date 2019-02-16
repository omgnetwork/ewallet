# Copyright 2019 OmiseGO Pte Ltd
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
  alias Ecto.Query
  alias EWallet.InviteEmail
  alias EWallet.{AccountMembershipPolicy, EmailValidator}
  alias EWallet.Web.{Inviter, Orchestrator, Originator, UrlValidator, V1.MembershipOverlay}
  alias EWalletDB.{Account, Membership, Repo, Role, User}

  @doc """
  Lists the users that are assigned to the given account.
  """
  def all_for_account(conn, %{"id" => account_id} = attrs) do
    with %Account{} = account <-
           Account.get(account_id, preload: [memberships: [:user, :role]]) ||
             {:error, :unauthorized},
         :ok <- permit(:get, conn.assigns, account.id),
         ancestor_uuids <- Account.get_all_ancestors_uuids(account),
         query <- Membership.all_by_account_uuids(ancestor_uuids),
         attrs <- transform_user_filter_attrs(attrs),
         %Query{} = query <- Orchestrator.build_query(query, MembershipOverlay, attrs),
         memberships <- Repo.all(query),
         memberships <- Membership.distinct_by_role(memberships) do
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
         :ok <- permit(:create, conn.assigns, account.id),
         {:ok, user_or_email} <- get_user_or_email(attrs),
         %Role{} = role <-
           Role.get_by(name: attrs["role_name"]) || {:error, :role_name_not_found},
         {:ok, redirect_url} <- validate_redirect_url(attrs["redirect_url"]),
         originator <- Originator.extract(conn.assigns),
         {:ok, _} <- assign_or_invite(user_or_email, account, role, redirect_url, originator) do
      render(conn, :empty, %{success: true})
    else
      {true, :user_id_not_found} ->
        handle_error(conn, :user_id_not_found)

      {:error, code} when is_atom(code) ->
        handle_error(conn, code)

      # Matches a different error format returned by Membership.assign_user/2
      {:error, changeset} ->
        handle_error(conn, :invalid_parameter, changeset)

      {:error, code, description} ->
        handle_error(conn, code, description)
    end
  end

  # Get user or email specifically for `assign_user/2` above.
  #
  # Returns:
  # - `%User{}` if user_id is provided and found.
  # - `:user_id_not_found` if `user_id` is provided but not found.
  # - `%User{}` if email is provided and found.
  # - `string` email if email provided but not found.
  #
  # If both `user_id` and `email` are provided, only `user_id` is attempted.
  # Hence the pattern matching for `%{"user_id" => _}` comes first.
  defp get_user_or_email(%{"user_id" => user_id}) do
    case User.get(user_id) do
      %User{} = user -> {:ok, user}
      _ -> {:error, :user_id_not_found}
    end
  end

  defp get_user_or_email(%{"email" => nil}) do
    {:error, :invalid_email}
  end

  defp get_user_or_email(%{"email" => email}) do
    case User.get_by_email(email) do
      %User{} = user -> {:ok, user}
      nil -> {:ok, email}
    end
  end

  defp validate_redirect_url(url) do
    if UrlValidator.allowed_redirect_url?(url) do
      {:ok, url}
    else
      {:error, :prohibited_url, param_name: "redirect_url", url: url}
    end
  end

  defp assign_or_invite(email, account, role, redirect_url, originator) when is_binary(email) do
    case EmailValidator.validate(email) do
      {:ok, email} ->
        Inviter.invite_admin(
          email,
          account,
          role,
          redirect_url,
          originator,
          &InviteEmail.create/2
        )

      error ->
        error
    end
  end

  defp assign_or_invite(user, account, role, redirect_url, originator) do
    case User.get_status(user) do
      :pending_confirmation ->
        user
        |> User.get_invite()
        |> Inviter.send_email(redirect_url, &InviteEmail.create/2)

      :active ->
        Membership.assign(user, account, role, originator)
    end
  end

  @doc """
  Unassigns the user from the given account.
  """
  def unassign_user(conn, %{
        "user_id" => user_id,
        "account_id" => account_id
      }) do
    with %Account{} = account <- Account.get(account_id) || {:error, :unauthorized},
         :ok <- permit(:delete, conn.assigns, account.id),
         %User{} = user <- User.get(user_id) || {:error, :user_id_not_found},
         originator <- Originator.extract(conn.assigns),
         {:ok, _} <- Membership.unassign(user, account, originator) do
      render(conn, :empty, %{success: true})
    else
      {:error, error} -> handle_error(conn, error)
    end
  end

  def unassign_user(conn, _attrs), do: handle_error(conn, :invalid_parameter)

  @spec permit(:all | :create | :get | :update | :delete, map(), String.t()) ::
          :ok | {:error, any()} | no_return()
  defp permit(action, params, account_id) do
    Bodyguard.permit(AccountMembershipPolicy, action, params, account_id)
  end
end
